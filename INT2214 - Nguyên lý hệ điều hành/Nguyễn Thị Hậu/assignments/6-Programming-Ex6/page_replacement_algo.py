from queue import Queue
import pandas as pd

class Solver():
    def fifo(self, page_seq, frame_no):
        n = len(page_seq)

        s = []
        q = Queue()

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (len(s) < frame_no):
                if (page_seq[i] not in s):
                    s.append(page_seq[i])

                    num_page_faults += 1

                    q.put(page_seq[i])

                    is_fault = 1
            else:
                if (page_seq[i] not in s):
                    val = q.get()

                    s[s.index(val)] = page_seq[i]

                    q.put(page_seq[i])

                    num_page_faults += 1

                    is_fault = 1

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def lru(self, page_seq, frame_no):
        n = len(page_seq)

        s = []
        indexes = {}

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (len(s) < frame_no):
                if (page_seq[i] not in s):
                    s.append(page_seq[i])

                    num_page_faults += 1

                    is_fault = 1

                indexes[page_seq[i]] = i
            else:
                if (page_seq[i] not in s):
                    mx = n

                    for page in s:
                        if (indexes[page] < mx):
                            mx = indexes[page]
                            val = page

                    s[s.index(val)] = page_seq[i];

                    num_page_faults += 1

                    is_fault = 1

                indexes[page_seq[i]] = i

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def mru(self, page_seq, frame_no):
        n = len(page_seq)

        s = []
        indexes = {}

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (len(s) < frame_no):
                if (page_seq[i] not in s):
                    s.append(page_seq[i])

                    num_page_faults += 1

                    is_fault = 1

                indexes[page_seq[i]] = i
            else:
                if (page_seq[i] not in s):
                    mx = -1

                    for page in s:
                        if (indexes[page] > mx):
                            mx = indexes[page]
                            val = page

                    s[s.index(val)] = page_seq[i]

                    num_page_faults += 1

                    is_fault = 1

                indexes[page_seq[i]] = i

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def lfu(self, page_seq, frame_no):
        n = len(page_seq)

        s = []
        frequencies = {}
        order = {}

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (page_seq[i] not in s):
                num_page_faults += 1

                is_fault = 1

                if (len(s) == frame_no):
                    # Get the least frequently used element
                    mn = n
                    idx = -1
                    mn_time_in = n
                    for id in range(len(s)):
                        order_list = order[s[id]]
                        if (mn > frequencies[s[id]]) or (mn == frequencies[s[id]] and mn_time_in > order_list[0]):
                            mn = frequencies[s[id]]
                            mn_time_in = order[s[id]][0]
                            idx = id
                            
                    order[s[idx]].pop(0)
                    frequencies[s[idx]] = 0
                    s[idx] = page_seq[i]
                else:
                    s.append(page_seq[i])

            if page_seq[i] not in order:
                order[page_seq[i]] = [] 
            order[page_seq[i]].append(i)
            frequencies[page_seq[i]] = frequencies.get(page_seq[i], 0) + 1

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def mfu(self, page_seq, frame_no):
        n = len(page_seq)

        s = []
        frequencies = {}
        order = {}

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (page_seq[i] not in s):
                num_page_faults += 1

                is_fault = 1

                if (len(s) == frame_no):
                    # Get the most frequently used element
                    mx = -1
                    idx = -1
                    mn_time_in = n
                    for id in range(len(s)):
                        order_list = order[s[id]]
                        if (mx < frequencies[s[id]]) or (mx == frequencies[s[id]] and mn_time_in > order_list[0]):
                            mx = frequencies[s[id]]
                            mn_time_in = order[s[id]][0]
                            idx = id
                            
                    order[s[idx]].pop(0)
                    frequencies[s[idx]] = 0
                    s[idx] = page_seq[i]
                else:
                    s.append(page_seq[i])

            if page_seq[i] not in order:
                order[page_seq[i]] = [] 
            order[page_seq[i]].append(i)
            frequencies[page_seq[i]] = frequencies.get(page_seq[i], 0) + 1

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def optimal(self, page_seq, frame_no):
        n = len(page_seq)

        s = []

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)

        result.append(format)

        occurrence = [None for i in range(frame_no)]

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            if (page_seq[i] not in s):
                is_fault = 1

                num_page_faults += 1

                if (len(s) < frame_no):
                    s.append(page_seq[i])
                else:
                    for x in range(len(s)):
                        if s[x] not in page_seq[i + 1:]:
                            s[x] = page_seq[i]
                            break
                        else:
                            occurrence[x] = page_seq[i + 1:].index(s[x])
                    else:
                        s[occurrence.index(max(occurrence))] = page_seq[i]

            p = list(s)

            for j in range(frame_no - len(p)):
                p.append('_')

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)


        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults

    def second_chance(self, page_seq, frame_no):
        def find_and_update(x, arr, sc, frame_no):
            for i in range(frame_no):
                if (arr[i] == x):
                    sc[i] = True

                    return True

            return False

        def replace_and_update(x, arr, sc, frame_no, pointer):
            while (True):
                if (not sc[pointer]):
                    arr[pointer] = x

                    return (pointer + 1) % frame_no

                sc[pointer] = False

                pointer = (pointer + 1) % frame_no

        n = len(page_seq)

        s = [-1] * frame_no
        sc = [False] * frame_no
        pointer = 0

        result = []

        format = []
        for i in range(frame_no):
            format.append(i)
        # format.append('pf')

        result.append(format)

        num_page_faults = 0
        faults = [-1]
        for i in range(n):
            is_fault = 0

            x = page_seq[i]

            if (not find_and_update(x, s, sc, frame_no)):
                pointer = replace_and_update(x, s, sc, frame_no, pointer)

                num_page_faults += 1

                is_fault = 1

            p = list(s)

            p = ['_' if x == -1 else x for x in p]

            faults.append(page_seq[i] if is_fault > 0 else -1)

            result.append(p)

        df = pd.DataFrame()

        for i in range(len(result)):
            df.insert(i, i, result[i])

        return df, faults, num_page_faults