import maude, sys
from tkinter import filedialog, messagebox
import tkinter as tk
import tkinter.ttk as ttk

class ReduceWindow:
	def __init__(self):
		self.window = tk.Tk()
		self.window.title('Maude bindings example')

		self.tbox = tk.Entry(self.window)
		self.tbox.grid(column=0, row=0)
		self.btn_tree = tk.Button(self.window, text='Tree', command=self.fillTree)
		self.btn_tree.grid(column=1, row=0)
		self.btn_red = tk.Button(self.window, text='Reduce', command=lambda: self.fillTree(True))
		self.btn_red.grid(column=2, row=0)
		self.tree = ttk.Treeview(self.window, columns=('sort'))
		self.tree.grid(column=0, row=1, columnspan=3)

		self.tree.heading('#0', text='Subterm')
		self.tree.heading('sort', text='Sort')

	def fillTree(self, doReduce=False):
		term = self.module.parseTerm(self.tbox.get())
		if term is None:
			messagebox.showerror('Maude bindings example', 'No parse for that term')
		else:
			if doReduce:
				term.reduce()
				self.tbox.delete(0, tk.END)
				self.tbox.insert(0, str(term))

			self.tree.delete(*self.tree.get_children())

			parent = self.tree.insert('', tk.END, text=str(term), values=str(term.getSort()))
			self.add_subterms(term, parent)

	def add_subterms(self, term, parent):
		for subterm in term.arguments():
			entry = self.tree.insert(parent, tk.END, text=str(subterm), values=str(subterm.getSort()))
			self.add_subterms(subterm, entry)

	def run(self):
		filename = filedialog.askopenfilename(title='Select Maude file',
				filetypes=[('Maude files', '*.maude')])

		if len(filename) == 0:
			sys.exit(1)

		maude.load(filename)
		self.module = maude.getCurrentModule()
		messagebox.showinfo('Maude bindings example',
			'Selected module is ' + str(self.module))

		self.window.mainloop()


if __name__ == '__main__':
	maude.init(advise=False)

	window = ReduceWindow()
	window.run()
