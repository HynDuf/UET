import tkinter as tk
from tkinter import simpledialog, messagebox
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from queue import Queue
import heapq
import matplotlib.cm as cm

def represents_int(s):
    try: 
        int(s)
    except ValueError:
        return False
    else:
        return True

def add(d, u, x):
    if u in d:
        d[u] += x
    else:
        d[u] = x;

def set_first_time(d, u, x):
    if not u in d:
        d[u] = x;

class CPUSchedulingAlgorithmsSolver:
    @staticmethod
    def FCFS(processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).
        If 2 processes have the same arrival time, the one with lower original indices 
        in the array will be dealt with first.

        Note: Priority is ignore in FCFS.
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        q = Queue()
        running_process = (None, None, None)
        segments = []
        while ptr < num_processes or running_process[0] != None or not q.empty():
            if running_process[2] != None and running_process[2] <= cur_time:
                segments.append((running_process[0], running_process[1], running_process[2] - running_process[1]))
                running_process = (None, None, None)
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                q.put((processes[ptr][0], processes[ptr][2]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if running_process[0] == None and not q.empty():
                p = q.get()
                running_process = (p[0], cur_time, cur_time + p[1])
                cpu_switches += 1
                set_first_time(response_time, p[0], cur_time - in_queue[p[0]])
                add(waiting_time, p[0], cur_time - in_queue[p[0]])
            cur_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def SJF_non_preemptive(processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).

        Note: Priority is ignore in SJF.
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        heap = []
        running_process = (None, None, None)
        segments = []
        while ptr < num_processes or running_process[0] != None or len(heap) > 0:
            if running_process[2] != None and running_process[2] <= cur_time:
                segments.append((running_process[0], running_process[1], running_process[2] - running_process[1]))
                running_process = (None, None, None)
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                heapq.heappush(heap, (processes[ptr][2], processes[ptr][0]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if running_process[0] == None and len(heap) > 0:
                p = heapq.heappop(heap)
                running_process = (p[1], cur_time, cur_time + p[0])
                cpu_switches += 1
                set_first_time(response_time, p[1], cur_time - in_queue[p[1]])
                add(waiting_time, p[1], cur_time - in_queue[p[1]])
            cur_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def SJF_preemptive(processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).

        Note: Priority is ignore in SJF.
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        heap = []
        running_process = (None, None, None)
        segments = []
        while ptr < num_processes or running_process[0] != None or len(heap) > 0:
            if running_process[2] != None and running_process[2] <= cur_time:
                segments.append((running_process[0], running_process[1], running_process[2] - running_process[1]))
                running_process = (None, None, None)
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                heapq.heappush(heap, (processes[ptr][2], processes[ptr][0]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if len(heap) > 0:
                if running_process[0] == None:
                    p = heapq.heappop(heap)
                    running_process = (p[1], cur_time, cur_time + p[0])
                    cpu_switches += 1
                    set_first_time(response_time, p[1], cur_time - in_queue[p[1]])
                    add(waiting_time, p[1], cur_time - in_queue[p[1]])
                else:
                    time_left = running_process[2] - cur_time
                    if time_left > heap[0][0]:
                        segments.append((running_process[0], running_process[1], cur_time - running_process[1]))
                        heapq.heappush(heap, (running_process[2] - cur_time, running_process[0]))
                        in_queue[running_process[0]] = cur_time

                        p = heapq.heappop(heap)
                        running_process = (p[1], cur_time, cur_time + p[0])
                        cpu_switches += 1
                        set_first_time(response_time, p[1], cur_time - in_queue[p[1]])
                        add(waiting_time, p[1], cur_time - in_queue[p[1]])

            cur_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def Priority_non_preemptive(processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        heap = []
        running_process = (None, None, None, None)
        segments = []
        while ptr < num_processes or running_process[0] != None or len(heap) > 0:
            if running_process[2] != None and running_process[2] <= cur_time:
                segments.append((running_process[0], running_process[1], running_process[2] - running_process[1]))
                running_process = (None, None, None, None)
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                heapq.heappush(heap, (processes[ptr][3], processes[ptr][2], processes[ptr][0]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if len(heap) > 0:
                if running_process[0] == None:
                    p = heapq.heappop(heap)
                    running_process = (p[2], cur_time, cur_time + p[1], p[0])
                    cpu_switches += 1
                    set_first_time(response_time, p[2], cur_time - in_queue[p[2]])
                    add(waiting_time, p[2], cur_time - in_queue[p[2]])

            cur_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def Priority_preemptive(processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        heap = []
        running_process = (None, None, None, None)
        segments = []
        while ptr < num_processes or running_process[0] != None or len(heap) > 0:
            if running_process[2] != None and running_process[2] <= cur_time:
                segments.append((running_process[0], running_process[1], running_process[2] - running_process[1]))
                running_process = (None, None, None, None)
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                heapq.heappush(heap, (processes[ptr][3], processes[ptr][2], processes[ptr][0]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if len(heap) > 0:
                if running_process[0] == None:
                    p = heapq.heappop(heap)
                    running_process = (p[2], cur_time, cur_time + p[1], p[0])
                    cpu_switches += 1
                    set_first_time(response_time, p[2], cur_time - in_queue[p[2]])
                    add(waiting_time, p[2], cur_time - in_queue[p[2]])
                else:
                    cur_priority = running_process[3]
                    if cur_priority > heap[0][0]:
                        segments.append((running_process[0], running_process[1], cur_time - running_process[1]))
                        heapq.heappush(heap, (running_process[3], running_process[2] - cur_time, running_process[0]))
                        in_queue[running_process[0]] = cur_time

                        p = heapq.heappop(heap)
                        running_process = (p[2], cur_time, cur_time + p[1], p[0])
                        cpu_switches += 1
                        set_first_time(response_time, p[2], cur_time - in_queue[p[2]])
                        add(waiting_time, p[2], cur_time - in_queue[p[2]])

            cur_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def RR(quantum_time, processes):
        '''
        'processes' must be a list of ('Process Name', Arrival Time, CPU Burst Time, Priority).

        Note: Priority is ignore in SJF.
        '''
        num_processes = len(processes)
        processes.sort(key=lambda p: p[1])

        cpu_burst_time = {}
        for p in processes:
            cpu_burst_time[p[0]] = p[2]
        in_queue = {}
        response_time = {}
        waiting_time = {}
        turn_around_time = {}
        cpu_switches = 0

        cur_time = 0
        ptr = 0
        q = Queue()
        running_process = (None, None, None)
        cur_quantum_time = 0
        segments = []
        while ptr < num_processes or running_process[0] != None or not q.empty():
            while ptr < num_processes and processes[ptr][1] <= cur_time:
                q.put((processes[ptr][2], processes[ptr][0]))
                in_queue[processes[ptr][0]] = cur_time
                ptr += 1
            if running_process[2] != None and (running_process[2] <= cur_time or cur_quantum_time == quantum_time):
                segments.append((running_process[0], running_process[1], cur_time - running_process[1]))
                if running_process[2] > cur_time:
                    q.put((running_process[2] - cur_time, running_process[0]))
                    in_queue[running_process[0]] = cur_time

                running_process = (None, None, None, None)
            if not q.empty() and running_process[0] == None:
                    p = q.get()
                    running_process = (p[1], cur_time, cur_time + p[0])
                    cur_quantum_time = 0
                    cpu_switches += 1
                    set_first_time(response_time, p[1], cur_time - in_queue[p[1]])
                    add(waiting_time, p[1], cur_time - in_queue[p[1]])

            cur_time += 1
            cur_quantum_time += 1
        for p in waiting_time:
            turn_around_time[p] = waiting_time[p] + cpu_burst_time[p]

        return segments, response_time, waiting_time, turn_around_time, cpu_switches

    @staticmethod
    def draw_gantt_chart(segments):
        '''
        `segments` must be a list of ('Process Name', Start Time, Duration). 
        The draw image will follow the order of elements in `segments`.
        '''
        # Generate a color map for unique process names
        unique_processes = {}
        cnt = 0
        for s in segments:
            if not s[0] in unique_processes:
                unique_processes[s[0]] = cnt
                cnt += 1
        color_map = cm.get_cmap('tab10', cnt)

        fig, ax = plt.subplots(figsize=(10, 2))

        for process in segments:
            idx = unique_processes[process[0]] 
            color = color_map(idx % len(unique_processes))
            ax.barh(0, process[2], left=process[1], height=0.5, align='center', label=process[0], color=color, edgecolor='black')
            ax.text(process[1] + process[2]/2, 0, process[0], ha='center', va='center', color='black', fontsize=16)

        ax.set_xlabel('Time')
        ax.set_yticks([0])
        ax.set_yticklabels(['Processes'])

        # Set more x-ticks
        x_ticks = np.arange(0, max(process[1] + process[2] for process in segments) + 1, 1)
        ax.set_xticks(x_ticks)

        return fig

num_processes = 0
global_option = ""
quantum_time = 0

def option_selected(option):
    global num_processes
    global rows
    global options_frame
    global next_button
    global priority_column
    global text_label
    global gantt_chart_canvas
    global global_option
    global quantum_time
    global_option = option
    
    num_processes = simpledialog.askinteger("Number of Processes", "Enter the number of processes:")
    
    # Check if num_processes is None (i.e., the user clicked cancel)
    if num_processes is None:
        return
    
    # Hide the options frame
    options_frame.grid_remove()
    
    # Clear previous rows
    for row in rows:
        row.destroy()
    
    # Add column names
    column_names = ["Process", "Arrival Time", "CPU Burst Time"]
    if option in ["Priority Non-preemptive", "Priority Preemptive"]:
        column_names.append("Priority")
        priority_column = True
    else:
        priority_column = False
    for i, name in enumerate(column_names):
        label = tk.Label(root, text=name, font=("Arial", 12, "bold"))
        label.grid(row=2, column=i, padx=5, pady=5)
    
    # Create rows for the table
    for i in range(num_processes):
        row = []
        for j in range(3 if not priority_column else 4):  # 3 columns by default, 4 if "Priority" column is needed
            if j == 0:
                label_text = f"P{i+1}"
                label = tk.Label(root, text=label_text, width=15)
                label.grid(row=i+3, column=j, padx=5, pady=5)
                row.append(label)
            else:
                entry = tk.Entry(root, width=15)
                entry.grid(row=i+3, column=j, padx=5, pady=5)
                row.append(entry)
        rows.append(row)
    
    # Change the title to "Please fill in the process's details"
    text_label.config(text="Please fill in the process's details")
    
    if option == "Round Robin":
        quantum_time = simpledialog.askinteger("Quantum Time", "Enter the quantum time (ms):")
        if quantum_time is None:  # Check if quantum_time is None (i.e., the user clicked cancel)
            return
        messagebox.showinfo("Option Selected", f"You chose option {option} with {num_processes} processes and quantum time {quantum_time} ms")
    else:
        messagebox.showinfo("Option Selected", f"You chose option {option} with {num_processes} processes")
        if "Priority" in option:
            messagebox.showinfo("Option Selected", f"Note that processes with LOWER priority is run first. If you want higher, multiply with -1")

    
    # Show the Next button
    next_button.grid(row=num_processes+4, column=3 if not priority_column else 4, pady=10, sticky=tk.SE)

def next_button_clicked():
    global num_processes
    global gantt_chart_canvas
    
    processes = []
    for i in range(num_processes):
        process_name = rows[i][0].cget("text")
        arrival_time = rows[i][1].get()
        cpu_burst_time = rows[i][2].get()
        priority = 0
        if priority_column:
            priority = rows[i][3].get()
        
        # Check if any parameter is not filled
        if not (represents_int(cpu_burst_time) and represents_int(arrival_time) and (not priority_column or represents_int(priority))):
            messagebox.showerror("Invalid Parameters", f"All parameters for process {process_name} must be integers.")
            return
        
        processes.append((process_name, int(arrival_time), int(cpu_burst_time), int(priority)))
    
    if global_option == "FCFS":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.FCFS(processes)
    elif global_option == "SJF Non-preemptive":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.SJF_non_preemptive(processes)
    elif global_option == "SJF Preemptive":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.SJF_preemptive(processes)
    elif global_option == "Priority Non-preemptive":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.Priority_non_preemptive(processes)
    elif global_option == "Priority Preemptive":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.Priority_preemptive(processes)
    elif global_option == "Round Robin":
        segments, response_time, waiting_time, turn_around_time, cpu_switches = CPUSchedulingAlgorithmsSolver.RR(quantum_time, processes)
    
    cpu_switches -= 1
    fig = CPUSchedulingAlgorithmsSolver.draw_gantt_chart(segments)
    
    if gantt_chart_canvas is not None:
        gantt_chart_canvas.get_tk_widget().destroy()
        
    gantt_chart_canvas = FigureCanvasTkAgg(fig, master=root)
    gantt_chart_canvas.draw()
    gantt_chart_canvas.get_tk_widget().grid(row=0, column=4, rowspan=num_processes+4, padx=10, pady=10)

    # Create the table
    table_frame = tk.Frame(root)
    table_frame.grid(row=num_processes+5, column=0, columnspan=4, pady=10)

    # Define column names for the table
    columns = ["Process", "Response Time", "Waiting Time", "Turnaround Time"]

    # Create labels for column names
    for i, col_name in enumerate(columns):
        label = tk.Label(table_frame, text=col_name, font=("Arial", 12, "bold"))
        label.grid(row=0, column=i, padx=5, pady=5)

    # Create rows for each process
    for i, process in enumerate(processes):
        process_name_label = tk.Label(table_frame, text=process[0])
        process_name_label.grid(row=i+1, column=0, padx=5, pady=5)

        response_time_label = tk.Label(table_frame, text=str(response_time[process[0]]))
        response_time_label.grid(row=i+1, column=1, padx=5, pady=5)

        waiting_time_label = tk.Label(table_frame, text=str(waiting_time[process[0]]))
        waiting_time_label.grid(row=i+1, column=2, padx=5, pady=5)

        turnaround_time_label = tk.Label(table_frame, text=str(turn_around_time[process[0]]))
        turnaround_time_label.grid(row=i+1, column=3, padx=5, pady=5)

    # Calculate average response time, waiting time, and turnaround time
    avg_response_time = sum(response_time.values()) / len(response_time)
    avg_waiting_time = sum(waiting_time.values()) / len(waiting_time)
    avg_turnaround_time = sum(turn_around_time.values()) / len(turn_around_time)

    # Create labels for average values
    avg_label = tk.Label(table_frame, text="Average:")
    avg_label.grid(row=num_processes+1, column=0, padx=5, pady=5)

    avg_response_label = tk.Label(table_frame, text=str(avg_response_time))
    avg_response_label.grid(row=num_processes+1, column=1, padx=5, pady=5)

    avg_waiting_label = tk.Label(table_frame, text=str(avg_waiting_time))
    avg_waiting_label.grid(row=num_processes+1, column=2, padx=5, pady=5)

    avg_turnaround_label = tk.Label(table_frame, text=str(avg_turnaround_time))
    avg_turnaround_label.grid(row=num_processes+1, column=3, padx=5, pady=5)

    # Add the number of CPU switches in the last row
    cpu_switches_label = tk.Label(table_frame, text=cpu_switches)
    cpu_switches_label.grid(row=num_processes+3, column=0, columnspan=4, padx=5, pady=5)

    cpu_switches_label = tk.Label(table_frame, text="CPU Switches")
    cpu_switches_label.grid(row=num_processes+3, column=0, padx=5, pady=5)
    
    # Change the text of the button to "Close" and bind it to a function to close the program
    next_button.config(text="Close", command=exit)

# Create the main window
root = tk.Tk()
root.title("CPU Scheduling Algorithms")


# Add text label indicating to fill in the process's details
text_label = tk.Label(root, text="CPU Scheduling Exercises (2324II_INT2214_4)\n21020007 - Huỳnh Tiến Dũng", font=("Arial", 14))
text_label.grid(row=0, column=0, columnspan=4, pady=20)

# Create a frame for the options
options_frame = tk.Frame(root)
options_frame.grid(row=1, column=0, padx=10, pady=10)

# Define the options
options = ["FCFS", "SJF Preemptive", "SJF Non-preemptive", "Priority Preemptive", "Priority Non-preemptive", "Round Robin"]

# Create buttons for each option
for i, option in enumerate(options):
    button = tk.Button(options_frame, text=option, width=20, height=2, 
                       command=lambda opt=option: option_selected(opt))
    button.grid(row=i, column=0, padx=5, pady=5)

# Create rows list to store Entry widgets
rows = []

# Create the Next button (hidden initially)
next_button = tk.Button(root, text="Next", width=10, height=2, command=next_button_clicked)

# Boolean to track whether "Priority" column should be shown
priority_column = False

# Create a variable to store the Gantt chart canvas
gantt_chart_canvas = None

# Create the Close button (hidden initially)
close_button = tk.Button(root, text="Close", width=10, height=2, command=root.destroy)
close_button.grid(row=num_processes+4, column=3 if not priority_column else 4, pady=10, sticky=tk.SE)
close_button.grid_remove()  # Hide the Close button initially

# Run the main event loop
root.mainloop()
