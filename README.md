# CovidGlobal
Code & model files for Rahmandad, Lim & Sterman (2020), Estimating the global spread of COVID-19

For any questions please contact [Tse Yang Lim](mailto:tylim@mit.edu)

### Analysis Code
Contains the Python code used for data pre-processing and model estimation, in .ipynb and .py formats, as well as Matlab code used for graphing of results.

**Important:** The model estimation code is intended to work with an experimental parallelised Vensim engine. With appropriate modifications to the main function calls (but not the analytical procedure), the same analysis can be run on regular commercially available Vensim DSS, though it will take *much* longer. Please contact [Tom Fiddaman](mailto:tom@ventanasystems.com) for information on the experimental Vensim engine.

### Data
Contains Vensim data files (.vdf) used in model estimation, as well as the raw .csv files assembled from various sources ([JHU CSSE](https://github.com/CSSEGISandData/COVID-19), [OWID](https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/testing/covid-testing-all-observations.csv), [World Bank](https://databank.worldbank.org/home.aspx), etc.) that are fed into the data pre-processing algorithm.

### Vensim Files
Contains the main Vensim model file (.mdl) and other supplementary Vensim files used for model estimation (e.g. optimization control, payoff definition, savelist files, and so on). Also includes two sub-models used for further analysis.