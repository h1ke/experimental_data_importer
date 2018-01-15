### DESCRIPTION
* This function processes experimental data files and extracts reaction time (RT) and accuracy (PC) data, as well as per-trial data.

### FILE INPUTS
* Data files with identical formatting and data arrangement.File called lists.txt containing headers and columns, where thefirst column is the list of all items (master list), and therest of the columns are lists of items in each condition, whichare subsets of the master list. File calledexclusion_list.txt containing a list of items to excludefrom statistics (this is usefull, when you have bad items).

### USER INPUTS
* Start and end rows for data files extraction, columns ofinterest(items, RT, and PC), delimiter for data files and listsfile, empty value assignment, coding for correct and incorrectresponses, RT upper and lower limits, regular expression startand end boundaries, and number and names of conditions.

### OUTPUT     
* Visual output of two tables containing extracted RT and PC data for the user to look over and correct potential errors duringparsing (MATLAB only). Console output of the names of datafiles processed. Console output of some stats on excluded datapoints. Two .txt files containing tab delimited tables of meansof RT and PC for subjects and items for each condition. Onedata file for mixed-effects models with per-trial data.

### OCTAVE	 
* Currently this program does not run properly in Octave, but itshould be possible to rewrite some portions of the code in orderto make the program Octave friendly.Let me know if you do this before me!

### EXAMPLE    
* The simplest way to run the program is to type its name in the console while the .m file is in your path-> RT_PC_data_importerYou can also run it by opening it in editor and clicking runbutton or pressing F5.

### NOTES ON LICENSE
* This software is covered under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) https://creativecommons.org/licenses/by-nc-sa/4.0/# The license does not permit incorporatingthis program into proprietary programs, where you can charge money for software!Under no circumstances you can use this program for your personal financial enrichment!
* See LICENSE file for full copyrights and use policy information.

_______________

### ADVANCED README

### NEEDED SOFTWARE

* The program runs on MATLAB.
* It has been fully tested on `MATLAB R2014a (8.3.0.532)` running on a 64-bit Linux.

### INSTALLATION and CONFIGURATION

* While no installation is required, the program has to be in your OCTAVE/MATLAB path or run from your current folder to function. However, the program does not require the lists file and data files to be in its path or in the software path.

* Unless you pass an argument with a different location, the list file should be in the same path as the data files; the result files are saved in that path.


### BEFORE USE

* Before running the program, you should place all your data files in one folder, along with lists.txt and exclusion_list.txt file. All data files should have identical column arrangement, formatting, data coding, and character encoding.


### BASIC USE

* Basic use involves running the program from console by typing experimental_data_importer, or by opening it in editor and clicking run button or pressing F5.

* The program will open a GUI prompt for selecting data files. You can select as many files as you like. Lists.txt and exclusion_list.txt files will be selected automatically from the same folder. After you choose data files, the program will present you with a prompt window where you can enter all user variables. After this, if everything went fine, you will get two tables (RT and PC) with parsed data (the tables are disabled under Octave), with row names representing your master list and column names representing data file names. These tables are for looking only -- they present raw data in a finalized way, so you can know where the statistics will be pulled. After you close or minimize the tables, you will have to press ENTER for the program to continue. It will run the statistics procedures and report some stats on excluded items. After everything is done, the program will present a window with a message about successful completion of the process and save results files in the folder containing data files.


### ADVANCED USE

* Hardcode user input variables so you can run the program without manually inputting them in the user input prompt window. You can do this by replacing values in line starting with `defaults = `.

* In order to take advantage of varargin parameters, pass arguments using console. For instance, if you want to change the default behaviour of getting the lists file from the same folder as the data files, lists file name, or saving data files in that folder, or both, you can pass the following command -->

`experimental_data_importer('lists_file','mylists.txt','path_lists',...
'/HDD1/exp/behavioural/data/RTs/,'save_path',...
'/HDD1/exp/behavioural/data/RTs/stats/')`

* Note that lists file name does not have to contain .txt, as long as it is a text file, it should work fine.


### BASIC TROUBLESHOOTING

* Most lines of code are commented in the program, so one should be able to figure out what went wrong and why by running code line by line. However, two things that are likely to break are regexp and textscan. You will have to use <doc regexp> and <doc textscan> to learn more about these functions. For instance, a very common error is "Index exceeds matrix dimensions." This can be due to many reasons, but the usual one is that either your list has a wrong number of items (see below for an info on regexp) or one of data files has a wrong number of items or more/less lines than you have specified in your user inputs. 

* Encoding (UTF8, UTF16, ASCII, etc.) of the files might affect textscan performance. As the program is written now, it uses your default system-wide encoding for all incoming files, if a data file has a different encoding, you will get an error. Check the encoding and tweak textscan parameters. To find out your current default character encoding, type the following line in your console --> `feature('DefaultCharacterSet')` To find out file encoding for a given file under Unix type in terminal --> `file -i <file_name>`

* Regexp finishes its scan once it has the first match; and it will find embedded items. Therefore, you should make sure you give a strict boundaries for it to look for items. For instance, if your are looking for item "test" and it is in a string "test (205, test.wav)", regexp will find it in the beginning and will go to next item in your master list. Furthermore, if all your items start with "test", regexp will find many "test" items. Unless this is what you want, you should either instruct regexp that, for instance, items always have a space before them and have a period after, or instruct it to skip the first character -- this way it will not match "test" in the beginning.

* Because this is a function, it does not dump anything into your workspace. Try removing semicolon after a line of code you suspect is at fault, so you can see it's output in the console. In the alternative, use debugging feature of your software to engage in a full-scale debugging.


### FUTURE DIRECTIONS and CAVEATS

* The output files and data arrangements are intended for further statistical manipulation in R, so modify the fprintf routine to your liking if you are using a different software for statistical analysis. 

* Currently the program can only processes RT and PC only (as the name implies). It is desired to be able to process more variables in the future.  In addition, inherently, PC data is used for logical indexing of correct and incorrect responses, so you are basically dealing with one variable - RT.

