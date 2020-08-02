1) Before running, make sure you have the following packages installed: a) pandas, b) numpy, c) scipy, d) statsmodels. To install, run 'pip install pandas numpy scipy statsmodels'

2) Save the .py and .csv files in your data subfolder. The .py file will copy the final .vdfx/.vdf files to the parent directory of where the .py file is located (hence, put it in your data subfolder).

3) Make sure the .txt Control File is in the data subfolder as well.

4) Update the Vensim path in the Control File (under "vensimpath").

5) Use the "vdfname" field in the Control File to specify the prefix you want on the .vdfx/.vdf file names, including spaces. e.g. if "vdfname": "foo_", the .vdfx files will be "foo_ConstantData.vdfx", etc.

6) The "datalist" field in the Control File is a Python-formatted dictionary of names of .csv files (without the .csv extension) - 'constants' = constants data, 'flow' = daily infection & death rate data, 'form' = cumulative daily infection & death totals, 'test' = cumulative daily test data. You need to have all four files in the same folder as the .py file to run.

7) In the Control File, set "smoothing" to 'true' (without quotes) to turn on the data smoothing / time-shift algorithms, or 'false' to skip that step. NOTE: 'true' and 'false' are case-sensitive.

8) If "smoothing" is on, "smparams" is used to control the smoothing algorithm settings:
	a) mintestpoints - the minimum number of test data points for a country to be processed; countries with fewer test data points than mintestpoints will be skipped
	b) skiplist - a Python-list-formatted list of countries to skip regardless of data availability
	c) nrows - the number of countries (rows) in each dataset; should be left at 199
	d) windowlength - size of the moving average window for calculating deviations; should be an odd number, 7 or 11 are good values
	e) datathreshold - minimum data value (not number of data points) below which the smoothing algorithm will ignore a data point, to avoid being driven too much by random noise from small numbers
	f) smoothfactor - what proportion of an identified deviation will be smoothed out; should generally be between 0.5 and 0.75 to avoid insufficient or excessive smoothing out of noise
	g) borrowlength - how many subsequent days the algorithm will borrow from to fill a dip
	h) distlength - how many preceding days the algorithm will redistribute a peak over