% 
% AUTHOR       : hikea
%
% FUNCTION     : experimental_data_importer_v8.m
%
% DESCRIPTION  : This function processes experimental data files and
%                extracts reaction time (RT) and accuracy (PC) data, as well as
%		     per-trial data.
%
% FILE INPUTS  : Data files with identical formatting and data arrangement (see example data).
%                File called lists.txt containing headers and columns, where the
%                first column is the list of all items (master list), and the
%                rest of the columns are lists of items in each condition, which
%                are subsets of the master list. File called
%                exclusion_list.txt containing a list of items to exclude
%                from statistics (this is usefull, when you have bad items).
%
% USER INPUTS  : Start and end rows for data files extraction, columns of
%                interest(items, RT, and PC), delimiter for data files and lists
%                file, empty value assignment, coding for correct and incorrect
%                responses, RT upper and lower limits, regular expression start
%                and end boundaries, and number and names of conditions.
%                                    
% OUTPUT       : Visual output of two tables containing extracted RT and PC data 
%                for the user to look over and correct potential errors during
%                parsing (MATLAB only). Console output of the names of data
%                files processed. Console output of some stats on excluded data
%                points. Two .txt files containing tab delimited tables of means
%                of RT and PC for subjects and items for each condition. One
%                data file for mixed-effects models with per-trial data.
%
% OCTAVE	   : Currently this program does not run properly in Octave, but it
%                should be possible to rewrite some portions of the code in order
%                to make the program Octave friendly.
%                Let me know if you do this before me!
%
% EXAMPLE      : The simplest way to run the program is to type its name in the 
%                console while the .m file is in your path-> RT_PC_data_importer
%                You can also run it by opening it in editor and clicking run
%                button or pressing F5.
%
% NOTES        : See README for additional information and advanced examples.
%                See LICENSE for copyrights and use policy information.
%
%                Last edited on March 26, 2017.
%



function RT_PC_data_importer(varargin)

%%Check the passed parameters.
%first set some variables
files = [];
path_files = '';
path_lists = '';
lists_file = 'lists.txt';
exclusion_list_file = 'exclusion_list.txt';
save_path = '';
%check the parameters
%N.B. I put only the most useful parameters. I don't think one will use any other,
%but feel free to experiment with the rest.
for arg=1:length(varargin)
    if(strcmpi(varargin{arg}, 'files')) %this allows to pass data file names
        files = varargin{arg+1};
            if ~exist(files, 'file')
                files = [];
            end
    elseif(strcmpi(varargin{arg}, 'path_files')) %this allows to pass the path for the files 
        path_files = varargin{arg+1};
            if ~exist(path_files, 'dir')
                path_files = path_files;
            end            
    elseif(strcmpi(varargin{arg}, 'lists_file'))%this allows to change the name of lists file 
        lists_file = varargin{arg+1};
            if ~exist(lists_file, 'file')
                lists_file = lists_file;
            end
     elseif(strcmpi(varargin{arg}, 'path_lists'))%this allows to pass the path for lists file 
            path_lists = varargin{arg+1};
            if ~exist(path_lists, 'dir')
                path_lists = path_lists;
            end
     elseif(strcmpi(varargin{arg}, 'save_path'))%this allows to pass the path for results files 
            save_path = varargin{arg+1};
            if ~exist(save_path, 'dir')
                save_path = path_files;
            end            
     elseif (strcmpi(varargin{arg}, 'conditions'))%set number of conditions using this parameter
            n_of_cond = (varargin{arg+1});
    end
end


%%Step 1: Get files using gui
while isempty(files) || isempty(path_files) %if no files and path to files were provided use gui to get them
[files, path_files] = uigetfile({'*A1.txt';'*B1.txt';'*C1.txt';'*A2.txt';'*B2.txt';'*C2.txt';'*A3.txt';'*B3.txt';'*C3.txt';'*.txt';...
    '*A1NN.txt';'*B1NN.txt';'*C1NN.txt';'*A2NN.txt';'*B2NN.txt';'*C2NN.txt';'*A3NN.txt';'*B3NN.txt';'*C3NN.txt';'*.txt';'*A1AM.txt';...
    '*A2AM.txt';'*B1AM.txt';'*B2AM.txt';'*.txt';'*A1CH.txt';'*A2CH.txt';'*B1CH.txt';'*B2CH.txt'}, 'MultiSelect', 'on'); %look for .txt. files only, and save file names and path
if isequal(files,0)
   disp('You have canceled file selection!');
else
   disp(['You have selected ',(files)]); %display the names of selected files
end
end

%error handling for file selection gui
if isnumeric(files) %if no files are selected - the files' cell is a double and contains a 0
    fprintf('Please rerun the program and select at least one file!\n'); %display a message
    return %stop running the program, i.e. return control to command prompt
end

%%Step 2: Initialize necessary variables
%use gui dialog box for user inputs field prompts
prompt = {'Start row:','End row:','Column for items:','Column for RT:','Column for PC:','Delimiter:',...
    'Empty values:','Coding for correct:','Coding for incorrect:','RT upper cutoff:','RT lower cutoff:',...
    'Regexp start boundary:','Regexp end boundary:','Number of conditions:','Names of conditions(space separated)'};
title = 'User inputs'; %dialog title
numlines = 1; %number of lines per field
%default answers. N.B> hardcode these to avoid entering them each time for the same data files
%defaults={'7','246','5','11','10','\t','-inf','C','I','2000','400','[^]','','2','hi low'}; % '[^]' means ignore first character for regexp
%defaults={'3','402','14','21','15','\t','-inf','1','0','2500','250','','','4','word_HD nonword_HD word_LD nonword_LD'};
defaults={'29','604','2','7','6','\t','-inf','1','0','3000','200','\s',')','4', 'easy_match easy_mismatch hard_match hard_mismatch'};

%defaults={'33','608','3','8','7','\t','-inf','1','0','3000','200','\s',')','9',...
%    'nasal_canon nasal_non_canon nasal_unrelated schwa_canon schwa_non_canon schwa_unrelated medial_canon medial_non_canon medial_unrelated'};

%defaults={'31','533','2','7','6','\t','-inf','1','0','3000','200','\s',')','6',...
%    'reg-match reg-mismatch irreg-match irreg-mismatch irregpp-match irregpp-mismatch'};

user_inputs = inputdlg(prompt,title,numlines,defaults); %dialog box launch command

%error handling for user inputs gui
if isempty(user_inputs)
    fprintf('Please rerun the program, provide all user inputs, and click ''OK'' button!\n'); %display a message
    return %stop running the program, i.e. return control to command prompt
end

%check if the files array is a cell and turn it into a cell if not
%this is to make sure that the script can process 1 file
if ~iscell(files)
    files = cellstr(files);
end

%start and end rows for data files extraction
startRow = str2double(user_inputs{1});
endRow = str2double(user_inputs{2});
%columns of interest
items_column = str2double(user_inputs{3});
RT_column = str2double(user_inputs{4});
PC_column = str2double(user_inputs{5});
%delimiter
delimiter = user_inputs{6};
%empty value assignment
EmptyValue = str2double(user_inputs{7});
%PC data coding
one_or_zero = ['0';'1']; %define a string with desired coding
if any(strcmp(one_or_zero,user_inputs(8))) && any(strcmp(one_or_zero,user_inputs(9)))
%if PC is coded with 1 and 0, convert them to doubles
correct = str2double(user_inputs{8});
incorrect = str2double(user_inputs{9});
else %else keep them as is. N.B. they will still get converted, but later in the processing
correct = user_inputs{8};
incorrect = user_inputs{9};
end
%RT upper and lower limits
RT_upper = str2double(user_inputs{10});
RT_lower = str2double(user_inputs{11});
%regexp start and end boundary
regexp_bgn = user_inputs{12};
regexp_end = user_inputs{13};
%number of conditions in the lists file
n_of_cond = str2double(user_inputs{14});
lists_cols = n_of_cond+1; %number of columns in lists file
%names of conditions
condition_names=strsplit(user_inputs{15}); %define condition names

%load master list
if isempty(path_lists) %use path for files if path for lists is empty
    path_lists = path_files;
end
%read items from the file
fid_lists = fopen(fullfile(path_lists,lists_file),'r'); %create fid with full path
lists = textscan(fid_lists,repmat('%s',[1,lists_cols]),'Delimiter', delimiter,'HeaderLines',1); %textscan the lists file ignoring headers

master_list = lists{1}; %create a cell with master list
conditions = lists(:,[2:lists_cols]); %create a cellarray with conditions lists
fclose(fid_lists); %close file

%get rid of empty cells
master_list(cellfun('isempty',master_list)) = [];
%the double cellfun suggestions was an answer to my question here --> 
%http://stackoverflow.com/questions/30386982/matlab-remove-empty-cells-from-within-cell-array
conditions = cellfun(@(x) x(~cellfun('isempty', x)), conditions, 'uni', 0); %or 'UniformOutput', false)

%convert to a smiple cell, so we don't have to use cellfun in the following commands
conditions = horzcat(conditions{1:end}); 

%load exclusion list
%read items from the file
fid_exclusion_list = fopen(fullfile(path_files,exclusion_list_file),'r'); %create fid with full path
exclusion_list = textscan(fid_exclusion_list,'%s'); %read first column only
exclusion_items = exclusion_list{1}; %create a cell with master list
fclose(fid_exclusion_list); %close file

%Could update the master list with the exclusion list here without going into further complications! 


%%Step 3: Loop through each data file and extract relevant data
for i = 1:size(files',1) %N.B. transpose files cell to get correct size
file_base = strrep(files, '.txt', ''); %strip off the file extension to figure out the base file name
file_base = cellstr(file_base); %convert from character array to cell for fopen
warning off MATLAB:iofun:UnsupportedEncoding; %turn off warnings about unsupported encoding formats
fid_in = fopen(fullfile(path_files,files{i}),'r'); %create fid with full path
                                    %N.B. add 'l','UTF16-LE' parameters for utf16 encoded files (ex. some e-prime files)
%do this only for the first file, i.e. first iteration
if i == 1

%preallocate data matrices for user defined variables during the first iteration
RT_data = NaN(size(master_list,1),size(file_base',1)); %use NaN for numeric data matrix
if ~isnumeric(correct) || ~isnumeric(incorrect)
PC_data = cell(size(master_list,1),size(file_base',1));%and cell array for character or mixed data
else
PC_data = NaN(size(master_list,1),size(file_base',1));%or NaN if data is encoded with numbers
end
trial_data = NaN(size(master_list,1),size(file_base',1));

%initialize some necessary variables
pre_formatSpec = [];
row = [];

%get formatSpec during the first iteration from the first file
for ii = 1:startRow %the last recorded line in the memory will be startRow
                    %and it will determine the formatSpec.
                    %If your data is different after the first line
                    %(ex. a given column in the first line has a numeric value,
                    %but later there are some mixed characters (except
                    %'NaN','nan', or empty values)), the script will break - you will need to
                    %manually fix this, or read the data using a different
                    %formatSpec - perhaps a hardcoded one.
    
    row = fgetl(fid_in); %read file line by line
end

% The following solution to get formatspec is taken from ezread function by Paul Taylor
% http://www.mathworks.com/matlabcentral/fileexchange/11026-ezread
% Parse the header string into separate headers
row_cell = textscan(row,'%s','delimiter',delimiter); % use '%q' to strip off quotation marks (in case you have them)
row_cell = row_cell{1};

% Read the first line of data to determine the column data types
for_formatSpec = textscan(row,'%q',length(row_cell),'delimiter',delimiter); % '%q' strips off quotation marks
for_formatSpec = for_formatSpec{1};

% Check the contents of each column and construct a column format specifier string
for iii = 1:length(for_formatSpec)
    % If str2num returns a numeric value, then the column is numeric,
    % if str2num returns empty, then the column is a text
    if ~isnan(str2double(for_formatSpec{iii}))
        col_format = '%f';
    else
        col_format = '%q'; %use '%q' to strips off quotation marks
    end
    pre_formatSpec = [pre_formatSpec col_format];
end

% Move back to the start of the file, so the first file can be correctly textscanned
frewind(fid_in)

end %end of the procedures for the first file


%%Import file based on discovered formatspec and user defined columns
%N.B. some of the solution do not work under octave, so we will use a different one if you are running octave
%solution taken from here --> http://stackoverflow.com/questions/2246579/how-do-i-detect-if-im-running-matlab-or-octave
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

if isOctave == 0
formatSpec_matlab = [pre_formatSpec '%*[^\n\r]']; %reassign formatSpec adding newline and carriage return. * means ignore anything before [^\n\r]

%textscan data file with discovered formatspec and user defined row range
data = textscan(fid_in, formatSpec_matlab, endRow(1)-startRow(1)+1,...
    'Delimiter', delimiter,'EmptyValue',EmptyValue, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
else
formatSpec_octave = [pre_formatSpec '\n\r']; %reassign formatSpec adding newline and carriage return - Octave

data = textscan(fid_in, formatSpec_octave, 'Delimiter', delimiter, endRow-startRow+1, 'HeaderLines', startRow-1);

end

%save user defined columns into vectors
items = data{items_column};
PC = data{PC_column};
RT = data{RT_column};

%loop through user defined column of items and match them with the master list items 
for iv = 1:size(master_list,1)

%create indices of found items
item_index = find(~cellfun('isempty', regexp(items,[regexp_bgn master_list{iv} regexp_end])));

%use indices of found items to pull data from user defined columns
RT_data(iv,i) = RT(item_index);
PC_data(iv,i) = PC(item_index);
trial_data(iv,i) = item_index;

end

fclose(fid_in); %close file

end %end importing all data files

%create cells containing condition names by items and subjects
%this is necessary for fprintf saving procedure later on
condition_names_itm = repmat(condition_names,[size(conditions,1) 1]);
condition_names_sbj = repmat(condition_names,[size(files',1) 1]);
sub_names_mix = repmat(file_base,[size(condition_names_itm,1) 1]);

%%Step 4: Create a table with acquired raw data (one for each user defined column/variable)
%and display them to the user
%N.B. this routine works under matlab only, so we will skip it if you are using Octave
%solution taken from here --> http://stackoverflow.com/questions/2246579/how-do-i-detect-if-im-running-matlab-or-octave
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

if isOctave == 0
    
PC_data_table = uitable(figure('units','normalized','outerposition',[0 0 1 1]),...
    'units','normalized','Position', [0 0 1 1],'Data',PC_data, 'ColumnName',...
    file_base,'RowName',master_list);
RT_data_table = uitable(figure('units','normalized','outerposition',[0 0 1 1]),...
    'units','normalized','Position', [0 0 1 1],'Data',RT_data, 'ColumnName',...
    file_base,'RowName',master_list);

%display a message and pause the script while user is looking over the tables
fprintf('After looking over the tables, please press ENTER to continue!\n');
pause
else
%display a message that tables will be skipped
fprintf('You are running Octave, so I am going to skip displaying tables with raw data!\n');
end

%%Step 5: Massage data, pull some descriptive stats,
%and save stats to tab delimited files

%replace letter coding to number coding if there is a letter coding
if ~isnumeric(correct) || ~isnumeric(incorrect)
%if coding is not numeric
PC_data=regexprep(PC_data,correct,'1'); %replace correct with 1
PC_data=regexprep(PC_data,incorrect,'0'); %replace incorrect with 0
PC_data = str2double(PC_data); %convert cellarray to a double
else %else leave as is, since it should be a double with number coding 
PC_data = PC_data;
end

%use exclusion list to remove items from RT and PC data metrices
%identify indices of items from exclusion list within master list
%setdiff solution taken from here --> http://uk.mathworks.com/matlabcentral/answers/45604-function-opposite-of-ismember
[master_list_with_exclusions,index_exclude] = setdiff(master_list, exclusion_items);
RT_data_with_exclusions = RT_data(index_exclude,:);
PC_data_with_exclusions = PC_data(index_exclude,:);
trial_data_with_exclusions = trial_data(index_exclude,:);

%replace extreme values defined by user input cutoffs with NaNs
RT_data_with_exclusions(RT_data_with_exclusions>RT_upper | RT_data_with_exclusions<RT_lower) = NaN;

%report the number and percentage of excluded data based on cutoffs
excluded_after_cutoffs = sum(sum(isnan(RT_data_with_exclusions))); %count all NaNs
exluded_after_cutoffs_prcnt = (excluded_after_cutoffs/(size(RT_data_with_exclusions,1)*size(RT_data_with_exclusions,2)))*100; %compute percentage
fprintf('I have excluded %d RT data points based on your cutoffs (%d>%d),\n which is %.2f percent of the data.\n'...
    ,excluded_after_cutoffs,RT_upper, RT_lower,exluded_after_cutoffs_prcnt); %display a message with the counts and percentage

%update PC_data, so items with NaN in RT_data have NaN in PC_data
%but before that, create a copy of PC_data so we can use it for logical
%indexing (NaN's cannot be converted to logical)
PC_data_with_exclusions_for_logical = PC_data_with_exclusions;
PC_data_with_exclusions(isnan(RT_data_with_exclusions)) = NaN;

%replace incorrect responses with NaNs
PC_data_idx = logical(PC_data_with_exclusions_for_logical); %create a logical index using 0 and 1 values within PC_data set
RT_data_with_exclusions(~PC_data_idx) = NaN; %use indexing within PC_data to replace values for incorrect responses within RT_data  
                                 %also, one can use a(logical(b)), where b is an array with 0s and 1s, but is not logcial

%report total number and percentage of excluded data based on cutoffs and incorrect responses
excluded_total = sum(sum(isnan(RT_data_with_exclusions))); %count all NaN
exluded_total_prcnt = (excluded_total/(size(RT_data_with_exclusions,1)*size(RT_data_with_exclusions,2)))*100; %compute percentage
fprintf('Total number of excluded data points based on cutoffs and incorrect responses is %d,\n which is %.2f percent of the data.\n'...
    ,excluded_total,exluded_total_prcnt); %display a message with the counts and percentage

%use path for files if save path is empty
if isempty(save_path)
    save_path = path_files;
end

%initialize output files
%by subjects
fid_out_sbj = fopen([save_path ['data_subjects_' lists_file '.txt']],'w'); %open file for data by subjects and create fid
%save tab-separated column headers
%define column format and names and save to file
fprintf(fid_out_sbj,'%s\t%s\t%s\t%s\t%s\n','sub','list','group','m_rt','m_pc');
%by item
fid_out_itm = fopen([save_path ['data_items_' lists_file '.txt']],'w'); %open file for data by items and create fid
%save tab-separated column headers
%define column format and names and save to file
fprintf(fid_out_itm,'%s\t%s\t%s\t%s\t%s\n','item','list','group','m_rt','m_pc');
%by subject and item N.B. for mixed-effects models
fid_out_mix = fopen([save_path ['data_mix_' lists_file '.txt']],'w'); %open file for data by items and create fid
%save tab-separated column headers
%define column format and names and save to file
fprintf(fid_out_mix,'%s\t%s\t%s\t%s\t%s\t%s\t%s\n','trial','item','sub','list','group','rt','correct');

%loop through each condition, create subset of data, get means within each
%condition, and save using fprintf
for v =1:length(condition_names)
%identify indices of items from conditions within master list
[conditions_with_exclusions,index_exclude_conds] = setdiff(conditions(:,v), exclusion_items);
[flags_conds,index_conds] = ismember(conditions_with_exclusions, master_list_with_exclusions);

%get means
%by subjects 
%RT
RT_data_conditions = RT_data_with_exclusions(index_conds,:); %get RTs from master RT data file based on indices for each condition
M_RT_sbj = nanmean(RT_data_conditions); %compute mean RTs for each subject within each condition
%PC
PC_data_conditions = PC_data_with_exclusions(index_conds,:); %get PCs from master PC data file based on indices for each condition
M_PC_sbj = nanmean(PC_data_conditions); %compute mean PCs for each subject within each condition
%by items
%RT
M_RT_itm = nanmean(RT_data_conditions'); %transpose is needed since we want to get means by rows, i.e. items
%PC
M_PC_itm = nanmean(PC_data_conditions');

%get trials from master trial_data data file based on indices for each condition
trial_data_conditions = trial_data_with_exclusions(index_conds,:); 

%save tab delimited columns of data of RT and PC using fprintf loops
%by subjects 
for vi = 1:size(files',1) %loop trough each line of each data variable and save to .txt file line by line
%define column format and date to be saved.
%use () for numeric data, and {} for strings
fprintf(fid_out_sbj,'%s\t%s\t%s\t%.8f\t%.8f\n',file_base{vi}',lists_file,condition_names_sbj{vi,v},M_RT_sbj(vi),M_PC_sbj(vi));
end
%by items
for vii = 1:size(conditions_with_exclusions,1) %loop trough each line of each data variable and save to .txt file line by line
%define column format and date to be saved.
%use () for numeric data, and {} for strings
fprintf(fid_out_itm,'%s\t%s\t%s\t%.8f\t%.8f\n',conditions_with_exclusions{vii},lists_file,condition_names_itm{vii,v},M_RT_itm(vii),M_PC_itm(vii));
end

%by subject and item N.B. for mixed-effects models
for viii = 1:size(files',1)

for xi = 1:size(conditions_with_exclusions,1) %loop trough each line of each data variable and save to .txt file line by line
%define column format and date to be saved.
%use () for numeric data, and {} for strings
fprintf(fid_out_mix,'%d\t%s\t%s\t%s\t%s\t%.8f\t%.8f\n',trial_data_conditions(xi,viii), conditions_with_exclusions{xi},sub_names_mix{xi,viii},lists_file,condition_names_itm{xi,v},RT_data_conditions(xi,viii),PC_data_conditions(xi,viii));
end

end

end

fclose(fid_out_sbj); %close file with data by subjects
fclose(fid_out_itm); %close file with data by items

%report the number of processed files
fprintf('I have successfully processed %d data files.\n' ,i);

%show a window with a message about successful completion of the task
message = sprintf('I have successfully processed %d data files.\n All data has been saved.\n', i); %message string
uiwait(msgbox(message)); %show a window displaying the message with "OK" button

end %end function
%
