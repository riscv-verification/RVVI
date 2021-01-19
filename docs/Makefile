all: doc

doc: rvvi.png
	eog $^
	
%.png: %.dot
	dot -Tpng $^ -o $@
	
clean:
	- rm -f rvvi.png
