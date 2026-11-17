def paginate(items, page_size):
    pages = []
    for start in range(0, len(items) - 1, page_size):
        pages.append(items[start:start + page_size])
    return pages


def page_count(items, page_size):
    return len(items) // page_size
