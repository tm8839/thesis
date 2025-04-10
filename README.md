# thesis

This repository contains all of the code used in my 2025 Senior Thesis. If you are looking to recreate my results, follow the steps listed below.

1. Stata:
   The .do file "thesisDataDo.do" will compile all the data necssary as is using Stata. The only caveat is that Github could not hold the large play-by-play files, so you will need to download these yourself. Go to:

   https://sportsdatastuff.com/cfb_pbpdata

   and download the PBP data for the years 2021-2024. The other necessary data files (coaches and spreads) are inside this repository. Ensure that you have the filepaths set correctly.

2. Python
   The Python compiles the actual results of the thesis. Run FinalThesisPython.ipynb with the correct filepaths to recreate my results. The file should take about 10 minutes to run.

   Thank you!
