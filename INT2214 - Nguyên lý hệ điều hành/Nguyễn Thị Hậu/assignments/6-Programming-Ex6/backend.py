# backend.py (Flask Backend)

from flask import Flask, render_template, request, jsonify
import page_replacement_algo
import matplotlib.pyplot as plt

app = Flask(__name__)
solver = page_replacement_algo.Solver()

class Renderer:
    def renderer(self, page_seq, df, conflicts):
        fig, ax = plt.subplots(figsize=(14, 6))

        page_seq.insert(0, 'ID / Page Seq')

        # Create the table
        table = plt.table(cellText=df.values,
                          colLabels=page_seq,
                          cellLoc='center',
                          loc='center',
                          bbox=[0, 0, 1, 1])

        # Style the table
        table.auto_set_font_size(False)
        table.set_fontsize(15)
        table.scale(1.2, 1.2)  # Adjust the table size

        # Hide axes
        ax.axis('off')

        h, w = df.shape

        for j in range(1, w):
            for i in range(h):
                if df.iat[i, j] == conflicts[j]:
                    table[i + 1, j].set_color('orange')
                    table[i + 1, j].set_edgecolor('black')

        # Remove whitespace
        plt.subplots_adjust(left=0, right=1, top=1, bottom=0)

        table_image_path = 'static/table_image.png'  # Save the image in the static folder
        plt.savefig(table_image_path, dpi=100, bbox_inches='tight', pad_inches=0)
        plt.close()  # Close the plot to release memory
        return table_image_path  # Return the path to the saved image

main_app = Renderer()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    selected_algo = int(request.form['selected_algo'])
    num_frames = int(request.form['num_frames'])
    split_char = None if ',' not in request.form['page_sequence'] else ','
    page_sequence = request.form['page_sequence'].split(split_char)

    # Perform calculation based on selected algorithm
    if selected_algo == 0:
        df, conflicts, page_faults = solver.fifo(page_sequence, num_frames)
    elif selected_algo == 1:
        df, conflicts, page_faults = solver.lru(page_sequence, num_frames)
    elif selected_algo == 2:
        df, conflicts, page_faults = solver.mru(page_sequence, num_frames)
    elif selected_algo == 3:
        df, conflicts, page_faults = solver.lfu(page_sequence, num_frames)
    elif selected_algo == 4:
        df, conflicts, page_faults = solver.mfu(page_sequence, num_frames)
    elif selected_algo == 5:
        df, conflicts, page_faults = solver.optimal(page_sequence, num_frames)
    elif selected_algo == 6:
        df, conflicts, page_faults = solver.second_chance(page_sequence, num_frames)
    else:
        return jsonify({'error': 'Invalid algorithm'})

    # Render the table image
    table_image_path = main_app.renderer(page_sequence, df, conflicts)

    # Prepare data to send back to frontend
    result = {
        'page_faults': page_faults,
        'page_faults_array': [p for p in conflicts if p != -1],
        'conflicts': conflicts,
        'df': df.to_json(orient='split'),
        'table_image': table_image_path  # Add the table image URL
        # Add other relevant data
    }

    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True)
