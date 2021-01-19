all: doc

doc: rvvi.png rvvi-tb.png
	eog --new-instance rvvi.png &
	eog --new-instance rvvi-tb.png &
	
%.png: %.dot
	echo "Create $@ from $<"
	dot -Tpng $^ -o $@
	
clean:
	- rm -f rvvi.png
