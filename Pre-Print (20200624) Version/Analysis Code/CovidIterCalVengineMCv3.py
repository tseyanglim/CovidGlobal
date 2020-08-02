import os
import subprocess
import re
import json
import time
import pandas as pd
from keyboard import press
from shutil import copy
from distutils.dir_util import copy_tree


def write_log(string, logfile):
    """Writes printed script output to a logfile"""
    with open(logfile,'a') as f:
        f.write(string + "\n")
    print(string)


def write_control_file(controlfile):
    """Parse controlfile text into list of appropriate script commands"""
    simsettings = ['payoff', 'sensitivity', 'optparm', 'savelist', 'senssavelist']
    cmdtext = []
    cmdtext.extend(["SPECIAL>NOINTERACTION\n",
                    f"SPECIAL>LOADMODEL|{controlfile['model']}\n"])

    if controlfile['data']:
        datatext = ','.join(controlfile['data'])
        cmdtext.append(f"SIMULATE>DATA|\"{datatext}\"\n")

    for setting in simsettings:
        if controlfile[setting]:
            cmdtext.append(f"SIMULATE>{setting}|{controlfile[setting]}\n")

    if controlfile['changes']:
        cmdtext.append(f"SIMULATE>READCIN|{controlfile['changes'][0]}\n")
        for file in controlfile['changes'][1:]:
            cmdtext.append(f"SIMULATE>ADDCIN|{file}\n")  

    cmdtext.append("\n")
    return cmdtext


def compile_script(scriptname, controlfile, simtype='o', sens2filesettings=''):
    """Compile controlfile and optimization command into actual command script file"""
    simcmd = {'o': "RUN_OPTIMIZE", 'r': "RUN", 's': "RUN_SENSITIVITY"}
        
    script_text = write_control_file(controlfile)
    
    script_text.extend([f"SIMULATE>RUNNAME|{scriptname}\n",
                        f"MENU>{simcmd[simtype]}|o\n"])
    
    if simtype =='s':
        script_text.append(f"MENU>SENS2FILE|!|!|{sens2filesettings}\n")
    else:
        script_text.append(f"MENU>VDF2TAB|!|!|{controlfile['savelist']}|\n")
    
    script_text.extend(["SPECIAL>CLEARRUNS\n",
                        "MENU>EXIT\n"])
    
    with open(f"{scriptname}.cmd", 'w') as scriptfile:
        scriptfile.writelines(script_text)
    

def modify_mdl(country, modelname, newmodelname):
    """Opens .mdl as text, identifies Rgn subscript, and replaces with appropriate country name"""
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
    
    vocmain = []
    voccty = []
    vocfull = filedata
    
    for line in filedata:
        if line[0] == ':' or '[Rgn]' not in line:
            vocmain.append(line)
        if line[0] == ':' or '[Rgn]' in line:
            voccty.append(line)
    
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

    newdata = []
    for line in filedata:
        if any(k in line for k in linekey):
            newdata.append(line)

    with open(outfilename, 'w') as f:
        f.writelines(newdata)


def copy_model_files(controlfile, dirname):
    """Create subdirectory and copy relevant model files to it,
    then change working directory to subdirectory"""
    os.makedirs(dirname, exist_ok=True)
    
    # Copy needed files from the working directory into the sub-directory
    for file in ['model', 'payoff', 'optparm', 'sensitivity', 'savelist', 'senssavelist']:
        if controlfile[file]:
            copy(f"./{controlfile[file]}", f"./{dirname}")
    for filelist in ['data', 'changes', 'scenariolist']:
        for file in controlfile[filelist]:
            copy(f"./{file}", f"./{dirname}")
                       
    # Change working directory to the created sub-directory
    os.chdir(f"./{dirname}")
    

def create_mdls(controlfilename, logfile):
    """Creates copies of the base .mdl file for each country in list (and one main copy)
    and splits .VOC files"""
    cf = json.load(open(controlfilename, 'r'))
    model = cf['model']
    for c in cf['countrylist']:
        newmodel = model[:-4] + f'_{c}.mdl'
        modify_mdl(c, model, newmodel)

    mainmodel = model[:-4] + '_main.mdl'
    c_list = [f'{c}\\\n\t\t' if i % 8 == 7 else c for i,c in enumerate(countrylist)]
    countrylist_str = str(c_list)[1:-1].replace("'","")
    modify_mdl(countrylist_str, model, mainmodel)
    split_voc(cf['optparm'], cf['fractolfactor'], cf['mcsettings'])
    write_log("Files are ready! moving to calibration", logfile)


def read_payoff(outfile, line=1):
    """Identifies payoff value from .OUT or .REP file - 
    use line 1 (default) for .OUT, or use line 0 for .REP"""
    with open(outfile) as f:
        payoffline = f.readlines()[line]

    payoffvalue = [float(s) for s in re.findall(r'-?\d+\.?\d+[eE+-]*\d+', payoffline)][0]
    return payoffvalue


def compare_payoff(scriptname):
    """Returns the difference in payoffs between .OUT and .REP file, 
    which should be zero in most cases except when MCMC bugs out"""
    difference = read_payoff(f"{scriptname}.out") - read_payoff(f"{scriptname}.rep", 0)
    
    print(".OUT and .REP payoff difference is", difference)
    
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
                       

def run_vengine_script(vensimpath, scriptname, timelimit, logfile, simtype='o'):
    """Call Vensim with command script using subprocess; 
    monitor .log file for changes to see if Vensim has stalled out,
    and restart Vensim if it does, or if writing to .out fails;
    return payoff value of optimization run from .out file"""
    
    # Set output file to monitor based on simtype
    outfile = f"{scriptname}.log"
    if simtype == 'mc':
        pointsfile = f"{scriptname}_MCMC_points.tab"
    if simtype == 's':
        outfile = f"{scriptname}.vdf"
        
    while True:
        proc = subprocess.Popen(f"{vensimpath} \"./{scriptname}.cmd\"")
        time.sleep(2)
        press('enter') # Necessary to bypass the popup message in Vengine
        while True:
            try:
                proc.wait(timeout=timelimit)
                break
            except subprocess.TimeoutExpired:
                if os.path.exists(f"./{outfile}"):
                    write_log(f"Checking for {outfile}...", logfile)
                    timelag = time.time() - os.path.getmtime(f"./{outfile}")
                    # For MCMC, check timelag based on more recent of .log and .tab files
                    if simtype == 'mc':
                        if os.path.exists(f"./{pointsfile}"):
                            write_log(f"Checking for {pointsfile}...", logfile)
                            timelag = min(timelag, (time.time() - os.path.getmtime(f"./{pointsfile}")))
                    if timelag < (timelimit):
                        write_log(f"At {time.ctime()}, "
                                  f"{round(timelag,3)} seconds since last output, continuing...", 
                                  logfile)
                        continue
                    else:
                        proc.kill()
                        write_log(f"{timelag} seconds since last output. "
                                  "Calibration timed out!", logfile)
                        break
                else:
                    proc.kill()
                    write_log("Calibration timed out!", logfile)
                    break
        if proc.returncode != 1: # Note that Vengine returns 1 on MENU>EXIT, not 0!
            write_log(f"Return code is {proc.returncode}", logfile)
            write_log("Vensim! Trying again...", logfile)
            continue
        try:
            payoffvalue = 0 # Set default payoff value for simtypes that don't generate one
            if simtype == 'o':
                payoffvalue = read_payoff(f"{scriptname}.out")
                write_log(f"Payoff value for {scriptname} is {payoffvalue}", logfile)
                if check_zeroes(scriptname):
                    write_log(f"Help! {scriptname} is being repressed!", logfile)
                    continue # If Vengine zeroed parameters, retry run
                else:
                    break
            elif simtype == 'mc':
                if not os.path.exists(f"./{pointsfile}"):
                    continue
                elif compare_payoff(scriptname) != 0:
                    write_log(f"{scriptname} is a self-perpetuating autocracy! re-running MC...", 
                              logfile)
                    continue
                else:
                    break
            else:
                break
        except FileNotFoundError:
            write_log("Outfile not found! That's it, I'm dead.", logfile)
            pass
    
    time.sleep(2)
    
    return payoffvalue


def calibrate_initial(controlfilename, logfile):
    """Runs first calibration on each country with both general and [Rgn] parameters,
    then uses country-specific outputs to calibrate main model to get initial payoff"""
    cf = json.load(open(controlfilename, 'r'))
    countrylist = cf['countrylist']
        
    for c in countrylist:
        cf = json.load(open(controlfilename, 'r'))
        cf['model'] = cf['model'][:-4] + f"_{c}.mdl"
        cf['optparm'] = f"{cf['optparm'][:-4]}_i.voc"
                
        scriptname = f"{cf['baserunname']}_{c}_0"
        compile_script(scriptname, cf)
        write_log(f"Initialising {c}, iteration 0!", logfile)
        
        copy_model_files(cf, c)
        copy(f"../{scriptname}.cmd", "./")
        cf['genparams'].append(f"[{c}]")
        clean_outfile(f"{cf['changes'][0]}", cf['genparams'])
        run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile)
        
        # Copy the .out file to parent directory
        copy(f"./{scriptname}.out", "../")
        os.chdir("..")
        write_log(f"Initial run for {c} complete!", logfile)

    # Run main model calibration to get initial main payoff
    payoffvalue = calibrate_main(countrylist, controlfilename, 0, logfile)
                  
    return payoffvalue

    
def downsample(scriptname, samplefrac):
    """Downsamples an MCMC _sample tab file according to specified samplefrac, 
    then deletes MCMC _sample and _points files to free up disk space"""
    rawdf = pd.read_csv(f"{scriptname}_MCMC_sample.tab", sep='\t')
    newdf = rawdf.sample(frac=samplefrac)
    newdf.to_csv(f"{scriptname}_MCMC_sample_frac.tab", sep='\t', index=False)
    os.remove(f"{scriptname}_MCMC_sample.tab")
    os.remove(f"{scriptname}_MCMC_points.tab")
    

def calibrate_countries(countrylist, controlfilename, i, logfile, simtype='c'):
    """Iterates through countrylist, running calibration each time on [Rgn] parameters,
    using general parameters estimated from previous calibration iteration as input"""
    vocsuffix = {'c': '_c', 'mc': '_cmc'}
    namesuffix = {'c': f"{i}", 'mc': "MC"}
    
    for c in countrylist:
        cf = json.load(open(controlfilename, 'r'))
        if cf['changes']:
            cf['changes'].pop(0)
        cf['optparm'] = f"{cf['optparm'][:-4]}{vocsuffix[simtype]}.voc"
        cf['model'] = cf['model'][:-4] + f"_{c}.mdl"
        
        if simtype == 'c':
            cf['changes'].append(f"{cf['baserunname']}_main_{i-1}.out")
            if os.path.exists(f"./{cf['baserunname']}_{c}_{i-1}.out"):
                cf['changes'].append(f"{cf['baserunname']}_{c}_{i-1}.out")
        elif simtype == 'mc':
            cf['changes'].append(f"{cf['baserunname']}_main_{i}.out")
                
        scriptname = f"{cf['baserunname']}_{c}_{namesuffix[simtype]}"
        compile_script(scriptname, cf)
        write_log(f"Initialising {c}, iteration {namesuffix[simtype]}!", logfile)
                
        copy_model_files(cf, c)
        copy(f"../{scriptname}.cmd", "./")
        if simtype == 'c':
            run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile)
        elif simtype == 'mc':
            cf['genparams'].append(f"[{c}]")
            clean_outfile(f"{cf['changes'][0]}", cf['genparams'])
            run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile, simtype='mc')
            downsample(scriptname, cf['samplefrac'])
            copy(f"./{scriptname}_MCMC_sample_frac.tab", "../")
            
        copy(f"./{scriptname}.out", "../")
        os.chdir("..")
        write_log(f"{c}, iteration {namesuffix[simtype]} complete!", logfile)
        
                                 
def calibrate_main(countrylist, controlfilename, i, logfile, simtype='m'):
    """Runs calibration on with main model copy; for 'm' setting, calibrates 
    general parameters only, using [Rgn] parameters estimated for each country 
    in previous calibration iteration as input; for 'f' setting, calibrates 
    all parameters; for 'mc' setting, runs MCMC for general parameters; for 'b' 
    setting, bypasses iterations and runs all-params based on last outfile"""
    
    vocsuffix = {'m': '_m', 'f': '_f', 'mc': '_mmc', 'b': '_f'}
    logmsg = {'m': f"Start main run no. {i}? Alright!", 
              'f': "Start all-parameters optimization? Off we go then!", 
              'mc': "Initialising main MCMC!", 
              'b': "Jumping straight to all-parameters optimization!"}
        
    cf = json.load(open(controlfilename, 'r'))
    
    cf['model'] = cf['model'][:-4] + "_main.mdl"
    cf['optparm'] = f"{optparm[:-4]}{vocsuffix[simtype]}.voc"
    
    scriptname = f"{cf['baserunname']}_main_{i}"
    
    # Select changes files to append based on specified simtype
    if simtype != 'b':
        if cf['changes']:
            cf['changes'].pop(0)
    if simtype == 'm':
        if os.path.exists(f"./{cf['baserunname']}_main_{i-1}.out"):
            cf['changes'].append(f"{cf['baserunname']}_main_{i-1}.out")
        outfilelist = [f"{cf['baserunname']}_{c}_{i}.out" for c in countrylist]
        cf['changes'].extend(outfilelist)
    elif simtype == 'f':
        cf['changes'].append(f"{cf['baserunname']}_main_{i-1}.out")
        outfilelist = [f"{cf['baserunname']}_{c}_{i-1}.out" for c in countrylist]
        cf['changes'].extend(outfilelist)
    elif simtype == 'mc':
        cf['changes'].append(f"{cf['baserunname']}_main_{i}.out")
        scriptname = f"{cf['baserunname']}_main_MC"
    
    # Extend timelimit for full or full MC calibrations
    if simtype != 'm':
        cf['timelimit'] *= 5
    
    compile_script(scriptname, cf)
    write_log(logmsg[simtype], logfile)
    if simtype == 'mc':
        copy_model_files(cf, "MainMC")
        copy(f"../{scriptname}.cmd", "./")
        payoffvalue = run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile, simtype='mc')
        copy(f"./{scriptname}.out", "../")
        os.chdir("..")
        write_log("Main MCMC complete!", logfile)
    else:    
        payoffvalue = run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile)
    time.sleep(2)
    
    return payoffvalue


def merge_samples(baserunname, countrylist):
    """Combines downsampled MCMC outputs into a single sensitivity input tabfile"""
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


def calibrate_final(countrylist, controlfilename, i, logfile):
    """Runs a final overall simulation with parameter estimates from all previous MCMCs, 
    followed by a sensitivity analysis using the combined downsampled MCMC output"""
    cf = json.load(open(controlfilename, 'r'))
    
    merge_samples(cf['baserunname'], cf['countrylist'])
    
    cf['model'] = cf['model'][:-4] + "_main.mdl"
    if cf['changes']:
        cf['changes'].pop(0)
    cf['changes'].append(f"{cf['baserunname']}_main_{i}.out")
    outfilelist = [f"{cf['baserunname']}_{c}_MC.out" for c in countrylist]
    cf['changes'].extend(outfilelist)
    cf['sensitivity'] = f"{cf['baserunname']}_full.vsc"

    for cin in cf['scenariolist']:
        cf['changes'].append(cin)
                
        scriptname = f"{cf['baserunname']}_final_{cin[:-4]}"
        compile_script(scriptname, cf, 'r')
        write_log(f"Almost finished, starting final run for {cin[:-4]}!", logfile)
        payoffvalue = run_vengine_script(cf['vensimpath'], scriptname, cf['timelimit'], logfile, simtype='r')
        time.sleep(2)

        sensscriptname = f"{cf['baserunname']}_sens_{cin[:-4]}"
        compile_script(sensscriptname, cf, 's', '%#[')
        write_log(f"Let's take it in turns - sensitivty time for {cin[:-4]}!", logfile)
        payoffvalue = run_vengine_script(cf['vensimpath'], sensscriptname, cf['timelimit'], logfile, simtype='s')
        time.sleep(2)
        
        cf['changes'].pop()

        
def calibrate_submodels(submodlist, controlfilename, i, logfile):
    """Iterates through list of submodels, copying their respective auxiliary files 
    and running base and sensitivity runs on each in their own subfolders"""
        
    for submod in submodlist:
        cf = json.load(open(controlfilename, 'r'))
        
        # Copy submodel folder from parent directory
        copy_tree(f"../{submod}", f"./{submod}")
        copy(controlfilename, f"./{submod}")
        os.chdir(f"./{submod}")
        
        smcf = json.load(open(f"{submod}Control.txt", 'r'))
        
        # Copy and if needed clean data and changes files
        smcf['changes'].append(f"{cf['baserunname']}_main_{i}.out")
        for file in smcf['data']:
            copy(f"../{file}", "./")
        for file in smcf['changes']:
            copy(f"../{file}", "./")
        if smcf['submodparams']:
            clean_outfile(f"{cf['baserunname']}_main_{i}.out", smcf['submodparams'])
        
        scriptname = f"{cf['baserunname']}_{submod}"
        compile_script(scriptname, smcf, 'r')
        write_log(f"Running submodel {submod}!", logfile)
        run_vengine_script(cf['vensimpath'], scriptname, smcf['timelimit'], logfile, simtype='r')
        time.sleep(2)
        copy(f"./{scriptname}.vdf", "../")
        copy(f"./{scriptname}.tab", "../")
        
        if smcf['sensitivity']:
            sensscriptname = f"{cf['baserunname']}_{submod}_sens"
            compile_script(sensscriptname, smcf, 's', '>T')
            write_log(f"Sensitivity time for {submod}!", logfile)
            run_vengine_script(cf['vensimpath'], sensscriptname, smcf['timelimit'], logfile, simtype='s')
            time.sleep(2)
            copy(f"./{sensscriptname}.tab", "../")
        
        os.chdir("..") # Remember to go back to main directory before next submodel run!


controlfilename = input("Enter control file name (with extension):")
controlfile = json.load(open(controlfilename, 'r'))

# Unpack controlfile into variables
for k,v in controlfile.items():
    exec(k + '=v')

copy_model_files(controlfile, f"{baserunname}_IterCal")
copy(f"../{controlfilename}", "./")
logfile = f"{os.getcwd()}\\{baserunname}.log"

# Initialise necessary .mdl and .voc files and payoff tracker, and run initial calibration
write_log(f"-----\nStarting new log at {time.ctime()}\nReady to work!", logfile)
create_mdls(controlfilename, logfile)

# If iterlimit set to 0 (bypass), go straight to all-params Powell optimization
if controlfile['iterlimit'] == 0:
    write_log("Iteration is no basis for a system of estimation. Bypassing!", logfile)
    i = int(controlfile['changes'][0][-5]) + 1
    calibrate_main(countrylist, controlfilename, i, logfile, 'b')
    
# Otherwise run iterative calibration process as normal
else:
    payoff_list = [calibrate_initial(controlfilename, logfile)]
    payoff_delta = abs(payoff_list[0])
    i = 1
    write_log(f"Initial payoff is {payoff_list}", logfile)

    # While payoff improvement is less than threshold, iterate through alternating calibrations
    while payoff_delta > threshold:
        write_log(f"More work? Okay! Starting iteration {i}", logfile)
        calibrate_countries(countrylist, controlfilename, i, logfile)
        payoffvalue = calibrate_main(countrylist, controlfilename, i, logfile)
        payoff_list.append(payoffvalue)
        payoff_delta = abs(payoff_list[-1] - payoff_list[-2])
        i +=1

        # Increment random number seeds for VOC files
        increment_seed(f"{controlfile['optparm'][:-4]}_c.voc", logfile)
        increment_seed(f"{controlfile['optparm'][:-4]}_m.voc", logfile)
        write_log(f"Payoff list thus far is {payoff_list}", logfile)
        write_log(f"Payoff delta is {payoff_delta}", logfile)
        if i > controlfile['iterlimit']:
            write_log("Iteration limit reached!", logfile)
            break
    else:
        write_log("Payoff delta is less than threshold. Moving on!", logfile)

    # Run one more full calibration with all parameters
    calibrate_main(countrylist, controlfilename, i, logfile, 'f')

# If MCMC option is on, initialise MCMC
if mccores != 0:
    write_log("We're an anarcho-syndicalist commune!\n"
              f"Initiating MCMC at {time.ctime()}!", logfile)
    calibrate_countries(countrylist, controlfilename, i, logfile, 'mc')
    write_log(f"MCMC completed at {time.ctime()}!", logfile)
    calibrate_final(countrylist, controlfilename, i, logfile)

# If submodel options are included, run submodel sensitivity tests
if submodlist:
    calibrate_submodels(submodlist, controlfilename, i, logfile)
    
write_log(f"Log completed at {time.ctime()}. Job done!", logfile)