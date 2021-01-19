all: doc

doc: rvvi.png rvvi-tb.png
	eog --new-instance $^ &
	
%.png: %.dot
	dot -Tpng $^ -o $@
	
clean:
	- rm -f rvvi.png
