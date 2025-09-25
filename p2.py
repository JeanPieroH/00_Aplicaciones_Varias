import pyperclip
import keyboard
import time
import google.generativeai as genai
import random
from pynput.mouse import Controller

# ==============================
# Configuración de la API
# ==============================
api_key = 'AIzaSyDUmPC1NwVAtnPoTENuw3rQzZy5AG0JPzU'
genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.5-flash')

# Crear un controlador del mouse
mouse = Controller()

def get_response_from_api(text):
    """
    Llama a la API y devuelve la letra de la respuesta (A,B,C,D,E)
    """
    prompt = f"""
    Te envío una pregunta tipo test.
    IMPORTANTE:
    - Responde SOLO con la letra (A,B,C,D o E).
    - Si la pregunta es de Verdadero/Falso, responde SOLO:
        A = Verdadero
        B = Falso
    
    Pregunta: {text}
    """
    response = model.generate_content(prompt)
    return response.text.strip().upper()[0]  # solo la primera letra


def mover_mouse_pendiente(dx, dy, duracion=1.2):
    """
    Mueve el mouse en un solo tramo con pendiente y aceleración suave.
    """
    x_inicio, y_inicio = mouse.position
    x_dest = x_inicio + dx + random.randint(-20, 20)  # desviación leve
    y_dest = y_inicio + dy + random.randint(-20, 20)

    # Movimiento del mouse a la nueva posición
    mouse.position = (x_dest, y_dest)


def mover_mouse(accion):
    """
    Decide hacia dónde mover el mouse según la acción recibida (A,B,C,D,E)
    """
    dx = random.randint(40, 70)
    dy = random.randint(40, 70)
    dur = random.uniform(0.8, 1.5)

    if accion == "A":
        mover_mouse_pendiente(0, -dy, dur)   # arriba
    elif accion == "B":
        mover_mouse_pendiente(dx, 0, dur)    # derecha
    elif accion == "C":
        mover_mouse_pendiente(0, dy, dur)    # abajo
    elif accion == "D":
        mover_mouse_pendiente(-dx, 0, dur)   # izquierda
    elif accion == "E":
        # Movimiento especial: primero arriba, luego derecha
        mover_mouse_pendiente(0, -dy, dur / 2)     # arriba
        mover_mouse_pendiente(dx, 0, dur / 2)      # derecha
    else:
        print(f"⚠ Acción desconocida: {accion}")


def on_copy():
    keyboard.press_and_release('ctrl+c')
    time.sleep(0.1)

    text = pyperclip.paste()

    respuesta = get_response_from_api(text)

    print(f"✅ Respuesta copiada: {respuesta}")

    # Ejecutar movimiento del mouse
    mover_mouse(respuesta)


def main():
    print("Presiona H, J o K para copiar y enviar la pregunta a la API...")
    print("Presiona Q para salir.")

    # Asignar hotkeys
    keyboard.add_hotkey('w', on_copy)
    keyboard.add_hotkey('e', on_copy)
    keyboard.add_hotkey('q', on_copy)

    keyboard.wait('r')  # salir con Q
    print("Programa finalizado.")


if __name__ == "__main__":
    main()
