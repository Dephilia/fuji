from pager import paginate

assert paginate([1, 2, 3, 4], 2) == [[1, 2], [3, 4]]
print("ok")
