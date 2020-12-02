import os
import subprocess
import re
import json
import time
import pandas as pd
from keyboard import press
from shutil import copy
from distutils.dir_util import copy_tree

class Script(object):
    """Master object for holding and modifying .cmd script settings, 
    creating .cmd files, and running them through Vensim/Vengine"""
    def __init__(self, controlfile):
        print("Initialising", self)
        for k, v in controlfile['simsettings'].items():
            self.__setattr__(k, v if isinstance(v, str) else v.copy())
        self.runcmd = "MENU>RUN_OPTIMIZE|o\n"
        self.savecmd = f"MENU>VDF2TAB|!|!|{self.savelist}|\n"
        self.basename = controlfile['baserunname']
        self.cmdtext = []
        
    def copy_model_files(self, dirname):
        """Create subdirectory and copy relevant model files to it,
        then change working directory to subdirectory"""
        os.makedirs(dirname, exist_ok=True)
        os.chdir(f"./{dirname}")

        # Copy needed files from the working directory into the sub-directory
        for s in ['model', 'payoff', 'optparm', 'sensitivity', 'savelist', 'senssavelist']:
            if getattr(self, s):
                copy(f"../{getattr(self, s)}", "./")
        for slist in ['data', 'changes']:
            for file in getattr(self, slist):
                copy(f"../{file}", "./")
            
    def add_suffixes(self, settingsfxs):
        """Cleanly modifies .cmd script settings with specified suffixes"""
        for s, sfx in settingsfxs.items():
            if hasattr(self, s):
                self.__setattr__(s, getattr(self, s)[:-4] + sfx + getattr(self, s)[-4:])
   
    def update_changes(self, chglist):
        """Reformats chglist as needed to extend changes settings; 
        see compile_script for details"""
        # Combines and flattens list of paired change names & suffixes
        flatlist = [i for s in 
                    [[f"{self.basename}_{n}_{sfx}.out" for n in name] 
                     if isinstance(name, list) else [f"{self.basename}_{name}_{sfx}.out"] 
                     for name, sfx in chglist] for i in s]
        self.changes.extend(flatlist)
          
    def write_script(self, scriptname):
        """Compiles and writes actual .cmd script file"""
        self.cmdtext.extend(["SPECIAL>NOINTERACTION\n", 
                             f"SPECIAL>LOADMODEL|{self.model}\n"])
        
        for s in ['payoff', 'sensitivity', 'optparm', 'savelist', 'senssavelist']:
            if hasattr(self, s):
                self.cmdtext.append(f"SIMULATE>{s}|{getattr(self, s)}\n")
        
        if hasattr(self, 'data'):
            datatext = ','.join(self.data)
            self.cmdtext.append(f"SIMULATE>DATA|\"{','.join(self.data)}\"\n")

        if hasattr(self, 'changes'):
            self.cmdtext.append(f"SIMULATE>READCIN|{self.changes[0]}\n")
            for file in self.changes[1:]:
                self.cmdtext.append(f"SIMULATE>ADDCIN|{file}\n")
        
        self.cmdtext.extend(["\n", f"SIMULATE>RUNNAME|{scriptname}\n", 
                             self.runcmd, self.savecmd, 
                             "SPECIAL>CLEARRUNS\n", "MENU>EXIT\n"])
        
        with open(f"{scriptname}.cmd", 'w') as scriptfile:
            scriptfile.writelines(self.cmdtext)
    
    def run_script(self, scriptname, controlfile, subdir, logfile):
        """Runs .cmd script file using function robust to 
        Vengine errors, and returns payoff value if applicable"""
        return run_vengine_script(scriptname, controlfile['vensimpath'], 
                                  controlfile['timelimit'], '.log', check_opt, logfile)

    
class CtyScript(Script):
    """Script subclass for country optimization runs"""
    def __init__(self, controlfile):
        super().__init__(controlfile)
        self.genparams = controlfile['genparams'].copy()
        
    def prep_subdir(self, scriptname, controlfile, subdir):
        """Creates subdirectory for country-specific files and output"""
        self.copy_model_files(subdir)
        copy(f"../{scriptname}.cmd", "./")
        self.genparams.append(f"[{subdir}]")
        for file in self.changes:
            clean_outfile(file, self.genparams)
            
    def run_script(self, scriptname, controlfile, subdir, logfile):
        self.prep_subdir(scriptname, controlfile, subdir)
        run_vengine_script(scriptname, controlfile['vensimpath'], 
                           controlfile['timelimit'], '.log', check_opt, logfile)
        copy(f"./{scriptname}.out", "..") # Copy the .out file to parent directory
        os.chdir("..")


class CtyMCScript(CtyScript):
    """Script subclass for country MCMC optimizations"""
    def run_script(self, scriptname, controlfile, subdir, logfile):
        self.prep_subdir(scriptname, controlfile, subdir)
        run_vengine_script(scriptname, controlfile['vensimpath'], 
                           controlfile['timelimit'], '_MCMC_points.tab', check_MC, logfile)
        
        # Create downsample and copy to parent directory
        downsample(scriptname, controlfile['samplefrac'])
        copy(f"./{scriptname}_MCMC_sample_frac.tab", "..")
        copy(f"./{scriptname}.out", "..") # Copy the .out file to parent directory
        os.chdir("..")

        
class LongScript(Script):
    """Script subclass for long calibration runs e.g. all-params"""
    def run_script(self, scriptname, controlfile, subdir, logfile):
        return run_vengine_script(scriptname, controlfile['vensimpath'], 
                                  controlfile['timelimit']*5, '.log', check_opt, logfile)


class ScenScript(Script):
    """Script subclass for scenario analysis with .cin files"""
    def update_changes(self, chglist):
        scen = chglist.pop()
        super().update_changes(chglist)
        self.changes.append(scen)
        chglist.append(scen)
        
    def run_script(self, scriptname, controlfile, subdir, logfile):
        return run_vengine_script(scriptname, controlfile['vensimpath'], 
                                  controlfile['timelimit'], '.vdf', check_run, logfile)
    

class ScenRunScript(ScenScript):
    """Script subclass for scenario analysis runs (not optimizations)"""
    def __init__(self, controlfile):
        super().__init__(controlfile)
        self.runcmd = "MENU>RUN|o\n"


class ScenSensScript(ScenScript):
    """Script subclass for scenario sensitivity analysis"""
    def __init__(self, controlfile):
        super().__init__(controlfile)
        self.sensitivity = self.basename + '_full.vsc'
        self.runcmd = "MENU>RUN_SENSITIVITY|o\n"
        self.savecmd = f"MENU>SENS2FILE|!|!|%#[\n"


class SMSensScript(ScenScript):
    """Script subclass for submodel sensitivity analysis"""
    def __init__(self, controlfile):
        super().__init__(controlfile)
        self.runcmd = "MENU>RUN_SENSITIVITY|o\n"
        self.savecmd = f"MENU>SENS2FILE|!|!|>T\n"
        

def compile_script(controlfile, scriptclass, name, namesfx, settingsfxs, 
                   logfile, chglist=[], subdir=None):
    """Master function for assembling & running .cmd script
    
    Parameters
    ----------
    controlfile : JSON object
        Master control file specifying sim settings, runname, etc.
    scriptclass : Script object
        Type of script object to instantiate, depending on run type
    name : str
    namesfx : str
        Along with `name`, specifies name added to baserunname for run
    settingsfxs : dict of str
        Dict of suffixes to append to filenames in simsettings; use to 
        distinguish versions of e.g. .mdl, .voc, .vpd etc. files
    logfile : str of filename/path
    chglist : list of tuples of (str or list, str)
        Specifies changes files to be used in script; specify as tuples 
        corresponding to `name`, `namesfx` of previous run .out to use; 
        tuples can also take a list of `names` as first element, taking 
        each with the same second element; `chglist` can also take one 
        non-tuple str as its last element, which will be added directly 
        (e.g. for policy scenario .cin files)
    subdir : str, optional
        Name of subdirectory to create/use for run, if applicable
    
    Returns
    -------
    float
        Payoff value of the script run, if applicable, else 0
    """
    mainscript = scriptclass(controlfile)
    mainscript.add_suffixes(settingsfxs)
    mainscript.update_changes(chglist)
    scriptname = f"{mainscript.basename}_{name}_{namesfx}"    
    mainscript.write_script(scriptname)
    return mainscript.run_script(scriptname, controlfile, subdir, logfile)


def write_log(string, logfile):
    """Writes printed script output to a logfile"""
    with open(logfile,'a') as f:
        f.write(string + "\n")
    print(string)
    

def check_opt(scriptname, logfile):
    """Check function for use with run_vengine_script for optimizations"""
    if check_zeroes(scriptname):
        write_log(f"Help! {scriptname} is being repressed!", logfile)
    return not check_zeroes(scriptname)

def check_MC(scriptname, logfile, threshold=0.01):
    """Check function for use with run_vengine_script for MCMC"""
    if abs(compare_payoff(scriptname, logfile)) >= threshold:
        write_log(f"{scriptname} is a self-perpetuating autocracy! re-running MC...", logfile)
        return False
    return True

def check_run(scriptname, logfile):
    """Check function for use with run_vengine_script for normal & sens runs"""
    if not os.path.exists(f"./{scriptname}.vdf"):
        write_log(f"Help! {scriptname} is being repressed!", logfile)
    return os.path.exists(f"./{scriptname}.vdf")

def run_vengine_script(scriptname, vensimpath, timelimit, checkfile, check_func, logfile):
    """Call Vensim with command script using subprocess; monitor output 
    file for changes to see if Vensim has stalled out, and restart if 
    it does, or otherwise bugs out; return payoff if applicable"""

    write_log(f"Initialising {scriptname}!", logfile)
    
    while True:
        proc = subprocess.Popen(f"{vensimpath} \"./{scriptname}.cmd\"")
        time.sleep(2)
        press('enter') # Necessary to bypass the popup message in Vengine
        while True:
            try:
                # Break out of loop if run completes within specified timelimit
                proc.wait(timeout=timelimit)
                break
            except subprocess.TimeoutExpired:
                try:
                    # If run not complete before timelimit, check to see if still ongoing
                    write_log(f"Checking for {scriptname}{checkfile}...", logfile)
                    timelag = time.time() - os.path.getmtime(f"./{scriptname}{checkfile}")
                    if timelag < (timelimit):
                        write_log(f"At {time.ctime()}, {round(timelag,3)}s since last output, "
                                  "continuing...", logfile)
                        continue
                    else:
                        # If output isn't being written, kill and restart run
                        proc.kill()
                        write_log(f"At {time.ctime()}, {round(timelag,3)}s since last output. "
                                  "Calibration timed out!", logfile)
                        break
                except FileNotFoundError:
                    # If output isn't being written, kill and restart run
                    proc.kill()
                    write_log("Calibration timed out!", logfile)
                    break
        if proc.returncode != 1: # Note that Vengine returns 1 on MENU>EXIT, not 0!
            write_log(f"Return code is {proc.returncode}", logfile)
            write_log("Vensim! Trying again...", logfile)
            continue
        try:
            # Ensure output is not bugged (specifics depend on type of run)
            if check_func(scriptname, logfile):
                break
        except FileNotFoundError:
            write_log("Outfile not found! That's it, I'm dead.", logfile)
            pass
    
    time.sleep(2)

    if os.path.exists(f"./{scriptname}.out"):
        payoffvalue = read_payoff(f"{scriptname}.out")
        write_log(f"Payoff for {scriptname} is {payoffvalue}, calibration complete!", logfile)
        return payoffvalue
    return 0 # Set default payoff value for simtypes that don't generate one


def modify_mdl(country, modelname, newmodelname):
    """Opens .mdl as text, identifies Rgn subscript, and replaces 
    with appropriate country name"""
    with open(modelname,'r') as f:
        filedata = f.read()
        
    rgnregex = re.compile(r"Rgn(\s)*?:(\n)?[\s\S]*?(\n\t~)")
    newdata = rgnregex.sub(f"Rgn:\n\t{country}\n\t~", filedata)

    with open(newmodelname,'w') as f:
        f.write(newdata)
    
                       
def split_voc(vocname, fractolfactor, mcsettings):
    """Splits .VOC file into multiple versions, for main, country, initial, 
    full model, general MCMC, and country MCMC calibration"""
    with open(vocname,'r') as f0:
        filedata = f0.readlines()
    
    vocmain = [line for line in filedata if line[0] == ':' or '[Rgn]' not in line]
    voccty = [line for line in filedata if line[0] == ':' or '[Rgn]' in line]
    vocfull = filedata.copy()
    vocinit = voccty.copy()
    
    # Identify and multiply fracitonal tolerance by fractolfactor for initial runs
    for l, line in enumerate(vocinit):
        if ':FRACTIONAL_TOLERANCE' in line:
            fractol = float(line.split('=')[1])
            vocinit[l] = f":FRACTIONAL_TOLERANCE={min(fractol*fractolfactor,0.1)}\n"
    
    # Set restarts to 1 for vocs besides initial
    for voc in (vocmain, voccty, vocfull):
        for l, line in enumerate(voc):
            if ':RESTART_MAX' in line:
                voc[l] = ':RESTART_MAX=1\n'
    
    vocmainmc = ''.join(vocmain)
    vocctymc = ''.join(voccty)
    
    # Make necessary substitutions for MCMC settings
    for k,v in mcsettings.items():
        vocmainmc = re.sub(f":{re.escape(k)}=.*", f":{k}={v}", vocmainmc)
        vocctymc = re.sub(f":{re.escape(k)}=.*", f":{k}={v}", vocctymc)
        
    # Write various voc versions to separate .voc files
    for fname, suffix in zip([vocmain, voccty, vocinit, vocfull, vocmainmc, vocctymc], 
                             ['m', 'c', 'i', 'f', 'mmc', 'cmc']):
        with open(f"{vocname[:-4]}_{suffix}.voc", 'w') as f:
            f.writelines(fname)
    

def check_zeroes(scriptname):
    """Check if an .out file has any parameters set to zero (indicates Vengine error),
    return True if any parameters zeroed OR if # runs = # restarts, and False otherwise"""
    filename = f"{scriptname}.out"
    with open(filename,'r') as f0:
        filedata = f0.readlines()
    
    checklist = []
    for line in filedata:
        if line[0] != ':':
            if ' = 0 ' in line:
                checklist.append(True)
            else:
                checklist.append(False)
        elif ':RESTART_MAX' in line:
            restarts = re.findall(r'\d+', line)[0]
    
    # Ensure number of simulations != number of restarts
    if f"After {restarts} simulations" in filedata[0]:
        checklist.append(True)
    
    return any(checklist)


def clean_outfile(outfilename, linekey):
    """Clean an outfile to include only lines containing a string in [linekey]
    Note that [linekey] should be a list of strings to keep"""
    with open(outfilename,'r') as f:
        filedata = f.readlines()

    newdata = [line for line in filedata if any(k in line for k in linekey)]
    
    with open(outfilename, 'w') as f:
        f.writelines(newdata)


def create_mdls(controlfile, logfile):
    """Creates copies of the base .mdl file for each country in list (and one main copy)
    and splits .VOC files"""
    model = controlfile['simsettings']['model']
    for c in controlfile['countrylist']:
        newmodel = model[:-4] + f'_{c}.mdl'
        modify_mdl(c, model, newmodel)

    mainmodel = model[:-4] + '_main.mdl'
    c_list = [f'{c}\\\n\t\t' if i % 8 == 7 else c for i,c in enumerate(countrylist)]
    countrylist_str = str(c_list)[1:-1].replace("'","")
    modify_mdl(countrylist_str, model, mainmodel)
    split_voc(controlfile['simsettings']['optparm'], 
              controlfile['fractolfactor'], controlfile['mcsettings'])
    write_log("Files are ready! moving to calibration", logfile)


def read_payoff(outfile, line=1):
    """Identifies payoff value from .OUT or .REP file - 
    use line 1 (default) for .OUT, or use line 0 for .REP"""
    with open(outfile) as f:
        payoffline = f.readlines()[line]
    payoffvalue = [float(s) for s in re.findall(r'-?\d+\.?\d+[eE+-]*\d+', payoffline)][0]
    return payoffvalue


def compare_payoff(scriptname, logfile):
    """Returns the difference in payoffs between .OUT and .REP file, 
    which should be zero in most cases except when MCMC bugs out"""
    difference = read_payoff(f"{scriptname}.out") - read_payoff(f"{scriptname}.rep", 0)
    write_log(f".OUT and .REP payoff difference is {difference}", logfile)
    return difference


def increment_seed(vocfile, logfile):
    """Increments random number seed in a .VOC file by 1"""
    with open(vocfile, 'r') as f:
        vocdata = f.read()
    seedregex = re.compile(r':SEED=\d+')
    try:
        i = int(re.search(r'\d+', re.search(seedregex, vocdata).group()).group())
        newdata = seedregex.sub(f":SEED={i+1}", vocdata)
        with open(vocfile, 'w') as f:
            f.write(newdata)
    except:
        write_log("No seed found, skipping incrementing.", logfile)
        
        
def downsample(scriptname, samplefrac):
    """Downsamples an MCMC _sample tab file according to specified 
    samplefrac, then deletes MCMC _sample and _points files to free 
    up disk space (files can be VERY large otherwise!)"""
    rawdf = pd.read_csv(f"{scriptname}_MCMC_sample.tab", sep='\t')
    newdf = rawdf.sample(frac=samplefrac)
    newdf.to_csv(f"{scriptname}_MCMC_sample_frac.tab", sep='\t', index=False)
    os.remove(f"{scriptname}_MCMC_sample.tab")
    os.remove(f"{scriptname}_MCMC_points.tab")

    
def merge_samples(baserunname, countrylist):
    """Combines downsampled MCMC outputs into a single sensitivity input
    tabfile and creates .vsc file using it for sensitivity control"""
    filelist = [f"{baserunname}_{c}_MC_MCMC_sample_frac.tab" for c in countrylist]
    dflist = []
    
    for f in filelist:
        ctydf = pd.read_csv(f, sep='\t')
        dflist.append(ctydf)
    
    sensdf = pd.concat(dflist, axis=1)
    sensdf.dropna(axis=1, how='all', inplace=True)
    sensdf.dropna().to_csv(f"{baserunname}_full_sample_frac.tab", sep='\t', index=False)
    
    with open(f"{baserunname}_full.vsc", 'w') as f:
        f.write(f",F,,{baserunname}_full_sample_frac.tab,0")


controlfilename = input("Enter control file name (with extension):")
cf = json.load(open(controlfilename, 'r'))

# Unpack controlfile into variables
for k,v in cf.items():
    exec(k + '=v')

# Set up files in run directory and initialise logfile
master = Script(cf)
master.changes.extend(scenariolist)
master.copy_model_files(f"{baserunname}_IterCal")
copy(f"../{controlfilename}", "./")
logfile = f"{os.getcwd()}/{baserunname}.log"
write_log(f"-----\nStarting new log at {time.ctime()}\nReady to work!", logfile)

# Initialise necessary .mdl and .voc files
create_mdls(cf, logfile)

# If iterlimit set to 0 (bypass), go straight to all-params Powell optimization
if iterlimit == 0:
    write_log("Iteration is no basis for a system of estimation. Bypassing!", logfile)
    # Skip all-params if previously already done
    if os.path.exists(f"./{baserunname}_main_full.out"):
        write_log("Hang on to outdated imperialist dogma! Using previous output...", logfile)
    else:
        compile_script(cf, LongScript, 'main', 'full', 
                       {'model': '_main', 'optparm': '_f'}, logfile)
    
# Otherwise run iterative calibration process as normal
else:
    # First do initial calibration round
    for c in countrylist:
        compile_script(cf, CtyScript, c, 0, 
                       {'model': f'_{c}', 'optparm': '_i'}, logfile, subdir=c)
    payoff_list = [compile_script(cf, Script, 'main', 0, {'model': '_main', 'optparm': '_m'}, 
                                  logfile, chglist=[(countrylist, 0)])]
    payoff_delta = abs(payoff_list[0])
    i = 1
    
    # Then iterate until convergence or until limit is reached
    while payoff_delta > threshold:
        write_log(f"More work? Okay! Starting iteration {i}", logfile)
        for c in countrylist:
            compile_script(cf, CtyScript, c, i, {'model': f'_{c}', 'optparm': '_c'}, 
                           logfile, chglist=[('main', i-1), (c, i-1)], subdir=c)
        payoff_list.append(
            compile_script(cf, Script, 'main', i, {'model': '_main', 'optparm': '_m'}, 
                           logfile, chglist=[('main', i-1), (countrylist, i)]))
        payoff_delta = abs(payoff_list[-1] - payoff_list[-2])
        i += 1

        # Increment random number seeds for VOC files
        increment_seed(f"{simsettings['optparm'][:-4]}_c.voc", logfile)
        increment_seed(f"{simsettings['optparm'][:-4]}_m.voc", logfile)
        write_log(f"Payoff list thus far is {payoff_list}", logfile)
        write_log(f"Payoff delta is {payoff_delta}", logfile)
        if i > iterlimit:
            write_log("Iteration limit reached!", logfile)
            break
    else:
        write_log("Payoff delta is less than threshold. Moving on!", logfile)

    # Run one more full calibration with all parameters
    compile_script(cf, LongScript, 'main', 'full', {'model': '_main', 'optparm': '_f'}, 
                   logfile, chglist=[('main', i-1), (countrylist, i-1)])

# If MCMC option is on, initialise MCMC
if mccores != 0:
    write_log("We're an anarcho-syndicalist commune!\n"
              f"Initiating MCMC at {time.ctime()}!", logfile)
    for c in countrylist:
        compile_script(cf, CtyMCScript, c, 'MC', {'model': f'_{c}', 'optparm': '_cmc'}, 
                       logfile, chglist=[('main', 'full')], subdir=c)
    write_log(f"MCMC completed at {time.ctime()}!", logfile)
    
    # Run fixed & sensitivity analysis for each scenario specified
    merge_samples(baserunname, countrylist)
    for cin in scenariolist:
        chglist = [('main', 'full'), (countrylist, 'MC'), cin]
        write_log(f"Running scenario {cin}!", logfile)
        compile_script(cf, ScenRunScript, 'final', cin[:-4], 
                       {'model': '_main'}, logfile, chglist=chglist)
        compile_script(cf, ScenSensScript, 'sens', cin[:-4], 
                       {'model': '_main'}, logfile, chglist=chglist)
        time.sleep(2)

# Run any submodels specified using their own controlfiles
for submod in submodlist:
    copy_tree(f"../{submod}", f"./{submod}")
    os.chdir(f"./{submod}")
    smcf = json.load(open(f"{submod}Control.txt", 'r'))
    for k in ['baserunname', 'vensimpath']:
        smcf[k] = cf[k]
    for file in smcf['simsettings']['changes'] + smcf['simsettings']['data']:
        copy(f"../{file}", "./")
    copy(f"../{smcf['baserunname']}_main_full.out", "./")
    clean_outfile(f"{smcf['baserunname']}_main_full.out", smcf['submodparams'])
    
    write_log(f"Running submodel {submod}!", logfile)
    compile_script(smcf, ScenRunScript, submod, 'base', {}, logfile, 
                   chglist=[f"{smcf['baserunname']}_main_full.out"], subdir=None)
    if smcf['simsettings']['sensitivity']:
        write_log(f"Sensitivity time for {submod}!", logfile)
        compile_script(smcf, SMSensScript, submod, 'sens', {}, logfile, 
                       chglist=[f"{smcf['baserunname']}_main_full.out"], subdir=None)
    os.chdir("..") # Remember to go back to main directory before next submodel run!

# Run sensitivity scenarios using specified variable-value combinations
for var, value in sensvars:
    var_val = f"{var.replace(' ','')[:8]}_{str(value).replace('.','')}"
    with open(f"{var_val}.cin",'w') as f:
        f.write(f"{var} = {value}")
    write_log(f"Running robustness check for {var} = {value}!", logfile)
    cf['simsettings']['changes'].append(f"{var_val}.cin")
    compile_script(cf, LongScript, 'sens', var_val, 
                   {'model': '_main', 'optparm': '_f'}, logfile, chglist=[('main', 'full')])
    compile_script(cf, ScenRunScript, 'sens', f'{var_val}_{scenariolist[0][:-4]}', 
                   {'model': '_main'}, logfile, chglist=[('sens', var_val), scenariolist[0]])
    cf['simsettings']['changes'].pop() # Remember to remove robustness CIN file!

# Run recalibration on sub-sample of countries, dropping those specified
for group, drops in droplist.items():
    write_log("\'tis but a scratch! Have at you!", logfile)
    shortlist = [c for c in countrylist if c not in drops]
    shortmodel = simsettings['model'][:-4] + f'_{group}.mdl'
    c_list = [f'{c}\\\n\t\t' if i % 8 == 7 else c for i,c in enumerate(shortlist)]
    countrylist_str = str(c_list)[1:-1].replace("'","")
    modify_mdl(countrylist_str, simsettings['model'], shortmodel)
    compile_script(cf, LongScript, 'sens', group, 
                   {'model': f'_{group}', 'optparm': '_f'}, logfile, chglist=[('main', 'full')])
    compile_script(cf, ScenRunScript, 'sens', f'{group}_{scenariolist[0][:-4]}', 
                   {'model': f'_{group}'}, logfile, chglist=[('sens', group), scenariolist[0]])

write_log(f"Log completed at {time.ctime()}. Job done!", logfile)