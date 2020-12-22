# CovidGlobal
Code & model files for Rahmandad, Lim & Sterman (2020), Behavioral Dynamics of COVID-19: Estimating Under-Reporting, Multiple Waves, and Adherence Fatigue Across 91 Nations (formerly: Estimating COVID-19 under-reporting across 86 nations: implications for projections and control)

For any questions please contact [Tse Yang Lim](mailto:tylim@mit.edu)

### Analysis Code
Contains the Python code used for data pre-processing and model estimation, in .ipynb and .py formats.

**Important:** The model estimation code is intended to work with an experimental parallelised Vensim engine. With appropriate modifications to the main function calls (but not the analytical procedure), the same analysis can be run on regular commercially available Vensim DSS, though it will take *much* longer. Please contact [Tom Fiddaman](mailto:tom@ventanasystems.com) for information on the experimental Vensim engine.

### Data
Contains Vensim data files (.vdf) used in model estimation, as well as the raw .csv files assembled from various sources ([JHU CSSE](https://github.com/CSSEGISandData/COVID-19), [OWID](https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/testing/covid-testing-all-observations.csv), [World Bank](https://databank.worldbank.org/home.aspx), etc.) that are fed into the data pre-processing algorithm.

### Initial Submission (20200803) Version
Archived version of repo containing files used in the first submission of the paper, as of 03 August 2020, as well as the pre-print version of the paper ([SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3635047), [MedRxiv](https://www.medrxiv.org/content/10.1101/2020.06.24.20139451v1)), released 24 June 2020. Note: files for the updated pre-print are in the current repo version.

### Online Simulator Files
Contains updated model version and data files used in the [online simulator](https://exchange.iseesystems.com/public/mitsdl/covidglobal/index.html). The simulator uses an updated model accounting for vaccination, as well as simplified data files. Updated data inputs used to estimate the model are in `Model Input Data`; estimated values fed into the simulator are in `Simulator Input Data`.

### Results
Contains output files from the model estimation presented in the paper, as well as Matlab code used for graphing of results, and output files from various robustness and sensitivity analyses (including synthetic data validation accompanying Supplement S3, out-of-sample validation results accompanying Supplement S6, and additional sensitivity analysis results accompanying Supplement S7).

### Vensim Files
Contains the main Vensim model file (.mdl) and other supplementary Vensim files used for model estimation (e.g. optimization control, payoff definition, savelist files, and so on), as well as models used for synthetic data analysis (Supplement S3).

