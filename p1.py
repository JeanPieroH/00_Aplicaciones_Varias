import google.generativeai as genai
import sys
import os

# ==============================
# CONFIGURACIÓN
# ==============================
API_KEY = "AIzaSyDUmPC1NwVAtnPoTENuw3rQzZy5AG0JPzU"

PROMPT_BASE = """
Contexto: Estoy resolviendo un problema de programación en selfie.

Restricciones:
1. Si se da un PDF, úsalo como contexto.
2. Responde solo a la "Petición" que envío.
"""

# ==============================
# INICIALIZACIÓN
# ==============================
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")


def enviar_con_pdf(ruta_pdf, prompt):
    """Envía el PDF junto con el prompt a la API."""
    try:
        file = genai.upload_file(path=ruta_pdf)
        response = model.generate_content([prompt, file])
        return response.text
    except Exception as e:
        print(f"❌ Error al procesar el PDF: {e}")
        return None


def enviar_solo_texto(prompt):
    """Envía solo texto a la API."""
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"❌ Error al procesar el texto: {e}")
        return None


def main():
    if len(sys.argv) < 2:
        print("Uso:")
        print("  python script.py <ruta_pdf>                # solo PDF")
        print("  python script.py \"<pregunta>\"             # solo texto")
        print("  python script.py <ruta_pdf> \"<pregunta>\"  # PDF + texto")
        sys.exit(1)

    arg1 = sys.argv[1]

    # Caso 1: Solo PDF
    if os.path.exists(arg1) and len(sys.argv) == 2:
        prompt_final = PROMPT_BASE + "\n\nPetición:\nExplica el contenido del PDF."
        respuesta = enviar_con_pdf(arg1, prompt_final)

    # Caso 2: Solo texto
    elif not os.path.exists(arg1) and len(sys.argv) == 2:
        pregunta = arg1
        prompt_final = PROMPT_BASE + "\n\nPetición:\n" + pregunta
        respuesta = enviar_solo_texto(prompt_final)

    # Caso 3: PDF + texto
    elif os.path.exists(arg1) and len(sys.argv) >= 3:
        ruta_pdf = arg1
        pregunta = " ".join(sys.argv[2:])
        prompt_final = PROMPT_BASE + "\n\nPetición:\n" + pregunta
        respuesta = enviar_con_pdf(ruta_pdf, prompt_final)

    else:
        print("❌ Argumentos inválidos.")
        sys.exit(1)

    if respuesta:
        print("\nRespuesta de la API:\n")
        print(respuesta)
    else:
        print("No se obtuvo respuesta.")


if __name__ == "__main__":
    main()
