Covid Iterative Calibration (Vengine version)
WARNING: THIS VERSION REQUIRES VENGINE TO RUN!

1) Save the .py file in the same folder as your model and relevant modelling files (.voc, .vpd, .vsc, .vdfx inputs, etc.). The program will copy all relevant files to a new subfolder and work there, as it will usually generate a lot of new files.

2) You need a single 'Control File' as input. This is a JSON-format .txt file which acts as a Python dictionary to control the calibration. Ensure that all fields are appropriately updated before running the .py file. Note that all strings will need to be "double-quoted". The order of fields does not matter.
	a) baserunname - the base name you want to use for the Vensim runs; also the name of the subfolder that will be created 
	b) model - the base .mdl file
	c) data - a Python-formatted list of .vdf/.vdfx data files to load
	d) payoff, sensitivity, optparm, savelist, senssavelist - the relevant Vensim control files (.vpd, .vsc, .voc, .lst, and .lst respectively)
	e) changes - a Python-formatted list of changes files to load (e.g. .cin, .out); NOTE: if the first changes file is an .out file, the script assumes it contains general params and will start the initial country-specific calibration on just country params
	f) vensimpath - filepath to your Vensim .exe - MAKE SURE TO UPDATE THIS
	g) countrylist - a Python-list-formatted list of subscript elements (countries) for the [Rgn] subscript
	h) threshold - absolute value of the payoff improvement from one iteration of main-model calibration (general, not [Rgn], parameters) to the next at which to automatically stop the calibration
	i) fractolfactor - factor by which to increase FRACTIONAL_TOLERANCE for initial round of country calibrations (for greater speed)
	j) samplefrac - the fraction of the MCMC samples to use for sensitivity analysis. If MCLIMIT is large, make sure this is quite small or your sensitivity analysis output will be massive!
	k) iterlimit - maximum number of iterations (through country-specific calibration first, then main-model calibration) to loop through before breaking the calibration - use as circuit breaker - to bypass iterative process, set this to 0 (be sure to have a previous main run .out file first in the changes list!)
	l) timelimit - maximum amount of time to wait between optimization runs of a single model (i.e. restarts) - if Vensim stalls out, this is how long the script will wait before killing Vensim and starting again
	m) genparams - a Python-formatted list of strings, used to identify lines in the first changes .out file to keep for initial country calibrations; typically this should be (as the name implies) the names of the general parameters
	n) scenariolist - a Python-formatted list of .cin files to use for scenario analysis at the end of the calibration process
	o) submodlist - a Python-formatted list of submodel names, to run submodels after calibration and sensitivity (if applicable)
		i) submodel names need to correspond to directory names in the root directory (same as the .py file), one per submodel, each containing all necessary submodel-specific files
		ii) submodels each have their own controlfile (named {submodel}Control.txt), with simplified format compared to the main one
		iii) submodel control files can have one additional field, submodparams, which should include all model parameters present in the submodel (used like genparams in the main controlfile)
	p) mccores - to turn off MCMC, set this to 0; if 1 or more, will run MCMC after completing iterative calibration
	q) mcsettings - a Python-formatted dictionary of Vensim optimization control settings to use for running MCMC. These will be used to modify the .voc file for the MCMC runs. The 'Sensitivity' and 'Multiple Start' settings should be left as-is; the 'MCLIMIT' setting gives the total number of iterations per MCMC process. Additional MCMC and optimization control settings can be added as desired.
	
3) Once the Control File is updated, ensure it is in the same folder as the .py file.

4) Run the .py file. It will prompt you for the name of the Control File, after which everything should run automatically.
	IMPORTANT: Vengine has a warning popup on initialization, which the script should dismiss automatically. There are two known times this may fail - on first running the script, and if your computer suspends or sleeps (even if running on server). For the first issue, on first running the script, if Vengine does not start running the optimization automatically after a few seconds, just manually dismiss the popup. For the second issue, I recommend that you change computer power settings to never sleep/suspend while running this script.

5) All output from the .py script will be written to a .log file under "{baserunname}.log".

6) When updating the Control File, watch out for commas and other punctuation! If you get a JSON decoder error when you input the Control File name, double-check the punctuation in the Control File.


IMPORTANT - note re: timelimit parameter
The timelimit parameter is only supposed to kill and restart Vensim if it is stalled out. As long as optimization is continuing (i.e. the optimization .log is still being written to), even if it the overall process takes longer than the timelimit, it will be allowed to complete - UNLESS a single optimization run does not yield any log file changes for longer than the timelimit. If optimization control settings are high-intensity enough that this happens, you WILL get stuck in an infinite loop - so if doing high-res optimization, adjust this parameter up accordingly. On the other hand, if set too high, more time will be wasted when Vensim does happen to stall out. Note that the timelimit is increased by 2 x for the MCMC runs due to these outputting log file changes less frequently.