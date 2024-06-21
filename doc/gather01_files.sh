# recursively find all *.cpp and *.h files in ../src, ../examples, ../test and ../include, ../README.md 
# print "start of <filename>\n" <contents of file> "\nend of <filename>\n"
# to stdout

find ../src ../examples ../test ../include ../README.md -type f -name "*.cpp" -o -name "*.h" | while read file; do
    echo "start of $file"
    cat $file
    echo "end of $file"
done