infile = pwd() * "\\out.douban"
outfile = pwd() * "\\out2.douban"
out = open(outfile, "w+")

for line in readlines(infile)
     #newline = replace(line, " ", ",")
     print(line)
     #write(out, newline)
 end
 close(out)