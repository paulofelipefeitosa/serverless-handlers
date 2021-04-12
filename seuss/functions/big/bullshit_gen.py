def next(name):
    n_list = list(name)
    cur = len(n_list) - 1
    if not n_list[cur] == 'z':
        n_list[cur] = chr(ord(n_list[cur]) + 1)
        return "".join(n_list)
    while cur >= 0 and n_list[cur] == 'z':
        n_list[cur] = 'a'
        cur -= 1
    if cur >= 0:
        n_list[cur] = chr(ord(n_list[cur]) + 1)
    return "".join(n_list)


previous = 'aaaaa'
print(previous + ' = ' + '1;')
for i in range(2, 375, 1):
    next_var = next(previous)
    print(next_var + ' = ' + previous + ' + ' + str(i) + ';')
    previous = next_var

