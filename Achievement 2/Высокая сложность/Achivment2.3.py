# Пример реализации сервера приложений на языке Python

from flask import Flask, request, jsonify

app = Flask(__name__)
processed_number = None

@app.route('/process', methods=['POST'])
def process_number():
    global processed_number

    data = request.get_json()

    if 'number' not in data:
        return jsonify({'error': 'Number not provided'}), 400

    number = data['number']

    if processed_number is not None and number == processed_number:
        return jsonify({'error': 'Number already processed'}), 400

    if processed_number is not None and number == processed_number - 1:
        return jsonify({'error': 'Received number is less than the processed number'}), 400

    processed_number = number + 1

    return jsonify({'result': processed_number})

if __name__ == '__main__':
    app.run(debug=True)
