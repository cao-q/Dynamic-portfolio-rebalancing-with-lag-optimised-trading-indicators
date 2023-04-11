function data = fetchData(filename)
in = importfile(strcat('..\data\', filename, '.csv'));
data = in{:, 5};