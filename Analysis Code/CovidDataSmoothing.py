import json
import subprocess
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from shutil import copy
from scipy import interpolate
from statsmodels.tsa.seasonal import STL


def import_datasets(datalist, vdfname):
    """ Creates Vensim script to convert CSVs to VDFs """
    print("Importing data to VDF...")
    scenario_text = []
    scenario_text.append("SPECIAL>NOINTERACTION\n")
    
    for dataname in datalist:
        scenario_text.append(f"MENU>CSV2VDF|{dataname}.csv|{vdfname}{dataname}|{dataname}.frm|\n")
    
    scenario_text.append("MENU>EXIT\n")
    
    scriptfile = open("ImportData.cmd", 'w')
    scriptfile.writelines(scenario_text)
    scriptfile.close()

    
def copy_data(datalist, vdfname):
    """ Copies VDFXs to parent directory of working directory """
    for dataname in datalist:
        for filetype in [".vdf", ".vdfx"]:
            try:
                copy(f"./{vdfname}{dataname}{filetype}", f"../")
            except FileNotFoundError:
                pass

            
def idx_to_int(df):
    """Converts string numeric column keys of dataframe to int"""
    Tdf = df.T
    Tdf.index = Tdf.index.astype('int')
    newdf = Tdf.T
    return(newdf)


def get_first_idx(s):
    return (s > 0).idxmax(skipna=True)


def get_last_idx(s):
    return s.where(s > 0).last_valid_index()


def calculate_devs(flowrow, windowlength, datathreshold, thresholdwidth=1):
    """Calculate rolling mean of series and adjusted deviations from the mean, as well as 
    threshold values based on median +/- MADs, ignoring values below given datathreshold"""
    flowmeanraw = flowrow.rolling(windowlength, min_periods=1, center=True).mean()
    flowmean = flowmeanraw.copy()
    flowmean.loc[:(flowmean >= datathreshold).idxmax()] = np.nan
    flowrawdev = flowrow - flowmean
    flowadjdev = flowrawdev / np.sqrt(flowmean)
    lowthreshold = flowadjdev.median() - flowadjdev.mad() * thresholdwidth
    highthreshold = flowadjdev.median() + flowadjdev.mad() * thresholdwidth
    devs = {'rawmean': flowmeanraw, 'mean': flowmean, 'rawdev': flowrawdev, 
            'adjdev': flowadjdev, 'lowthr': lowthreshold, 'highthr': highthreshold}
    return devs


def fill_dips(smflow, smdevs, k, smoothfactor, lowthreshold, borrowlength=7):
    """Identify points with deviations below threshold value and partially fill 
    by borrowing from following points, based on a multinomial draw with probabilities 
    proportional to deviations of those points"""
    for i, adjdev in enumerate(smdevs['adjdev'][:-k]):
        if adjdev < lowthreshold:
            borrowlist = smdevs['adjdev'].iloc[i+1:max(i+1+borrowlength, i+1)]
            values = smflow.iloc[i+1:max(i+1+borrowlength, i+1)]
            borrowlist -= adjdev
            borrowlist.mask(borrowlist < 0, other=0, inplace=True)
            if not all([(b == 0 or np.isnan(b)) for b in borrowlist]):
                borrowlist.astype('float64')
                borrowlist.dropna(inplace=True)
                borrowlist /= borrowlist.sum()
                mnlist = np.random.multinomial(abs(int(np.floor(smdevs['rawdev'].iloc[i]*smoothfactor))), 
                                               [abs(i) for i in borrowlist])
                mnlist = np.minimum(mnlist, values)
                smflow.iloc[i] += mnlist.sum()
                for j, val in enumerate(mnlist):
                    smflow.iloc[i+1+j] -= val

                
def smooth_peaks(smflow, smdevs, k, smoothfactor, highthreshold, distlength=14):
    """Identify points with deviations above threshold value and partially flatten 
    by distributing to preceding points, based on a multinomial draw with probabilities 
    proportional to existing rolling means of those points"""
    for i, adjdev in reversed(list(enumerate(smdevs['adjdev'][:-k]))):
        if adjdev > highthreshold:
            distlist = smdevs['rawmean'].iloc[max(0, i-distlength):i]
            if not all([(d == 0 or np.isnan(d)) for d in distlist]):
                distlist.astype('float64')
                distlist /= distlist.sum()
                mnlist = np.random.multinomial(abs(int(np.floor(smdevs['rawdev'].iloc[i]*smoothfactor))), distlist)
                smflow.iloc[i] -= mnlist.sum()
                for j, val in enumerate(mnlist):
                    smflow.iloc[i-len(mnlist)+j] += val


def iter_smooth(smflow, ordevs, windowlength, datathreshold, smoothfactor, 
                borrowlength=7, distlength=14, iterlimit=10):
    """Iteratively apply dip-filling and peak-smoothing algorithms until 
    all deviations are within the upper and lower median+/-MAD thresholds"""
    smdevs = calculate_devs(smflow, windowlength, datathreshold)
    i = 0
    while i < iterlimit:
        # If mean values are too low, skip all smoothing
        if np.nanmax(smdevs['mean']) < datathreshold:
            break
        # Identify last valid index and check if below threshold
        k = smflow.index.get_loc(get_last_idx(smflow))
        k = len(smflow) - k
        # Identify all consecutive final terms below threshold to skip, otherwise will cause errors
        while smdevs['adjdev'].iloc[-k] < ordevs['lowthr']:
            k +=1
        if np.nanmin(smdevs['adjdev'][:-k]) < ordevs['lowthr']:
            fill_dips(smflow, smdevs, k, smoothfactor, ordevs['lowthr'])
            smdevs = calculate_devs(smflow, windowlength, datathreshold)
        if np.nanmax(smdevs['adjdev'][:-k]) > ordevs['highthr']:
            smooth_peaks(smflow, smdevs, k, smoothfactor, ordevs['highthr'])
            smdevs = calculate_devs(smflow, windowlength, datathreshold)
        if (np.nanmax(smdevs['adjdev'][:-k]) < ordevs['highthr'] 
            and np.nanmin(smdevs['adjdev'][:-k]) > ordevs['lowthr']):
            break
        i += 1
    return smflow


def cross_corr(x, y, shift):
    """Get time-shifted cross-correlations of two series"""
    if shift > 0:
        xshift = x[0:-shift]
        yshift = y[shift:]
    elif shift < 0:
        xshift = x[-shift:]
        yshift = y[0:shift]
    elif shift == 0:
        xshift = x
        yshift = y

    rawcorrs = np.correlate(xshift, yshift, mode='full')
    normcorr = rawcorrs[(rawcorrs.size // 2):] / np.amax(rawcorrs)
    
    return normcorr[0]


def time_shift(x, shift):
    """Shift a series by a specified amount"""
    xshift = x.copy()
    if shift > 0:
        xshift[shift:] = x[0:-shift]
    elif shift < 0:
        xshift[0:shift] = x[-shift:]
    elif shift == 0:
        pass
    return xshift

    
def smooth_data(datalist, skiplist):
    """Run data smoothing and time shifting on data"""    
    print("Executing smoothing algorithm!")
    
    # Import dataframes from CSV and drop variable names
    testdf = pd.read_csv(f"{datalist['test']}.csv", index_col=1,header=0)
    testdf.drop(columns='Time', inplace=True)

    formdf = pd.read_csv(f"{datalist['form']}.csv", index_col=1,header=0)
    formdf.drop(columns='Time', inplace=True)

    flowdf = pd.read_csv(f"{datalist['flow']}.csv",index_col=1,header=0)
    flowdf.drop(columns='Time', inplace=True)

    # Convert string indices to int
    testdf = idx_to_int(testdf)
    formdf = idx_to_int(formdf)
    flowdf = idx_to_int(flowdf)

    # Set up sub-dataframes from main data files
    infdf = flowdf[0:nrows].copy()
    dthdf = flowdf[nrows:(nrows*2)].copy()
    recdf = flowdf[(nrows*2):(nrows*3)].copy()
    tratedf = testdf.replace(testdf, np.nan)
    tcapdf = testdf.replace(testdf, np.nan)
    
    # Convert infinite values to NaN to avoid potential errors
    testdf.replace([np.inf, -np.inf], np.NaN)
    
    for i in testdf.index:
        # Check if country is in skiplist
        if i in skiplist:
            print(f"Repressing {i}!")
            continue
        
        # Check if country has sufficient test data to proceed, else skip
        elif len(testdf.loc[i].dropna()) > mintestpoints:

            # Ensure cumulative test data is strictly monotonic increasing
            # NOTE: if monotonicity check happens after date value assignment, 
            # then if last test data point is nonmonotonic, it will be dropped causing an error
            testdf.loc[i] = testdf.loc[i].mask(testdf.loc[i].cummax().duplicated())

            # Identify first and last infection, test, and death date indices
            infA, testA = [get_first_idx(s) for s in [infdf.loc[i], testdf.loc[i]]]
            infZ, testZ, dthZ = [get_last_idx(s) for s in [infdf.loc[i], testdf.loc[i], dthdf.loc[i]]]

            # Assign 0 test value to first infection date if before first test date
            if infA < testA:
                newtestA = infA
                testdf.loc[i, newtestA] = 0
            else:
                newtestA = testA

            # Set test rate and capacity values to 0 before first data point
            tratedf.loc[i, :newtestA], tcapdf.loc[i, :newtestA] = 0, 0

            # Check whether original test data is sparse in latter half of test data window
            halftestrow = testdf.loc[i, newtestA:testZ]
            halftestrow = halftestrow.iloc[len(halftestrow)//2:]
            if len(halftestrow.dropna())/len(halftestrow) > 0.5:
                smcheck = False
            else:
                smcheck = True
                print(i, "is sparse:", len(testdf.loc[i]), len(halftestrow), len(halftestrow.dropna()))

            # Interpolate test data using PCHIP spline if possible, within range of presumed test data
            spline = interpolate.PchipInterpolator(testdf.loc[i].dropna().index, testdf.loc[i].dropna().values)
            interptests = spline(testdf.loc[i, newtestA:testZ].index)

            # Check if any interpolated values are negative; if so do linear interpolation instead
            if any((interptests[1:] - interptests[:-1]) < 0):
                print("Uh-oh, negative spline result, going linear!")
                linear = interpolate.interp1d(testdf.loc[i].dropna().index, testdf.loc[i].dropna().values)
                interptests = linear(testdf.loc[i, newtestA:testZ].index)

            # Assign interpolated values back to test data
            testdf.loc[i, newtestA:testZ] = interptests
            tratedf.loc[i, newtestA:testZ] = np.insert((interptests[1:] - interptests[:-1]), 0, interptests[0])

            # If original test data is sparse, smooth test and infection data
            if smcheck:
                tratedevs = calculate_devs(tratedf.loc[i, newtestA:testZ], windowlength, datathreshold)
                tratedf.loc[i, newtestA:testZ] = iter_smooth(tratedf.loc[i, newtestA:testZ], tratedevs, 
                                                             windowlength, datathreshold, smoothfactor)
                infdevs = calculate_devs(infdf.loc[i, :infZ], windowlength, datathreshold)
                infdf.loc[i, :infZ] = iter_smooth(infdf.loc[i, :infZ], infdevs, windowlength, datathreshold, smoothfactor)

            # Else if original test data not sparse, do time shift on test data
            else:
                minlen = min(len(tratedf.loc[i].dropna()), len(infdf.loc[i].dropna()))
                if minlen == 0:
                    print(f"Insufficient data for {i} shift, skipping!")
                else:
                    x = STL(tratedf.loc[i].dropna(), period=7, seasonal=7).fit().seasonal
                    y = STL(infdf.loc[i].dropna(), period=7, seasonal=7).fit().seasonal

                    alseas = x.align(y, join='inner')

                    seascorrs = []
                    shiftrange = list(range(-2,5))

                    for j in shiftrange:
                        seascorrs.append(cross_corr(alseas[0], alseas[1], j))

                    tshift = shiftrange[np.argmax(seascorrs)]
                    shifttrate = time_shift(tratedf.loc[i], tshift)

                    tratedf.loc[i] = shifttrate
                    newtestA += tshift
                    testZ += tshift

                    print(f"{i} shift is {tshift}")

            # Run polyfit on test rate data for later use to estimate test capacity
            # Test capacity will be estimated as max of fitted test rate LATER on whole DF
            pfit = np.polyfit(tratedf.loc[i, newtestA:testZ].index, tratedf.loc[i, newtestA:testZ].values, 10)
            tcapdf.loc[i, newtestA:testZ] = np.polyval(pfit, tratedf.loc[i, newtestA:testZ].index)

            # Run iterative dip/peak smoothing on death rates for all countries with enough deaths
            if np.nanmax(dthdf.loc[i]) > datathreshold:
                dthdevs = calculate_devs(dthdf.loc[i, :dthZ], windowlength, datathreshold)
                dthdf.loc[i, :dthZ] = iter_smooth(dthdf.loc[i, :dthZ], dthdevs, windowlength, datathreshold, smoothfactor)
                
        else:
            print(f"Not enough test data for {i}, skipping!")
    
    # Combine flow data streams into one dataframe
    smflowdf = pd.concat([infdf, dthdf, recdf], axis=0)

    # Set test capacity based on polyfit of test rate, ignoring first day
    tcapdf.iloc[:, 1:] = tcapdf.iloc[:, 1:].cummax(axis=1, skipna=False)

    # Recalculate cumulative tests based on smoothed test data
    testdf = tratedf.cumsum(axis=1, skipna=False)

    # Combine all three test data streams into one dataframe, dropping first day
    smtestdf = pd.concat([testdf, tratedf, tcapdf], axis=0).iloc[:,1:]

    # Shave NANs and last column of test dataframe
    smtestdf.dropna(axis=1, how='all', inplace=True)
    smtestdf = smtestdf.iloc[:,:-1]

    # Adjust first day flows to account for non-zero initial cumulative values
    smflowdf.iloc[:,0] += formdf.iloc[:,0]

    # Recalculate cumulative data from smoothed flows, then readjust first day flows
    smformdf = smflowdf.cumsum(axis=1)
    smflowdf.iloc[:,0] -= formdf.iloc[:,0]

    # Restore variable names and export to CSV
    smflowdf.reset_index(inplace=True)
    smflowdf.insert(0, 'Time', ['DataFlowInfection']*nrows+['DataFlowDeath']*nrows+['DataFlowRecovery']*nrows)
    smflowdf.to_csv(f"{datalist['flow']}.csv", index=False)

    smtestdf.reset_index(inplace=True)
    smtestdf.insert(0, 'Time', ['DataCmltTest']*nrows+['DataTestRate']*nrows+['DataTestCapacity']*nrows)
    smtestdf.to_csv(f"{datalist['test']}.csv", index=False)

    smformdf.reset_index(inplace=True)
    smformdf.insert(0, 'Time', ['DataCmltInfection']*nrows+['DataCmltDeath']*nrows+['DataCmltRecovery']*nrows)
    smformdf.to_csv(f"{datalist['form']}.csv", index=False)
        

controlfilename = input("Enter control file name (with extension):")
controlfile = json.load(open(controlfilename, 'r'))

# Unpack controlfile into variables
for k,v in controlfile.items():
    exec(k + '=v')

if smoothing == True:
    for k,v in smparams.items():
        exec(k + '=v')
    smooth_data(datalist, skiplist)

import_datasets(datalist.values(), vdfname)

subprocess.run(f"{vensimpath} \"./ImportData.cmd\"", check=True)

copy_data(datalist.values(), vdfname)
print("Job done!")
