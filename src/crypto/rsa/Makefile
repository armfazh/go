

all: bench

test:
	../../../bin/go test -run=".*" 
bench:
	../../../bin/go test -run="$$^" -bench="RSA"
	
	
