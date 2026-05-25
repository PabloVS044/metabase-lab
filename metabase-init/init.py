import requests
import os
import time
import glob

METABASE_URL = os.getenv("METABASE_URL", "http://retailmax_metabase:3000")
ADMIN_EMAIL = os.getenv("MB_ADMIN_EMAIL")
ADMIN_PASSWORD = os.getenv("MB_ADMIN_PASSWORD")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "retailmax_postgres")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_USER = os.getenv("POSTGRES_USER")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
QUERIES_PATH = os.getenv("QUERIES_PATH", "/queries")
DASHBOARD_NAME = os.getenv("DASHBOARD_NAME", "RetailMax Dashboard")
TAB_NAME = os.getenv("TAB_NAME", "Indicadores")


def wait_for_metabase():
    print("Esperando que Metabase esté listo...")
    for _ in range(60):
        try:
            r = requests.get(f"{METABASE_URL}/api/health", timeout=5)
            if r.json().get("status") == "ok":
                print("Metabase listo.")
                return
        except Exception:
            pass
        time.sleep(5)
    raise RuntimeError("Metabase no respondió a tiempo.")


def get_session_token():
    r = requests.get(f"{METABASE_URL}/api/session/properties", timeout=10)
    props = r.json()

    setup_token = props.get("setup-token")
    if setup_token:
        print("Intentando setup inicial de Metabase...")
        r = requests.post(f"{METABASE_URL}/api/setup", json={
            "token": setup_token,
            "user": {
                "email": ADMIN_EMAIL,
                "password": ADMIN_PASSWORD,
                "first_name": "Admin",
                "last_name": "RetailMax",
                "site_name": "RetailMax"
            },
            "prefs": {
                "site_name": "RetailMax",
                "allow_tracking": False
            }
        }, timeout=30)

        if r.status_code == 403:
            print("Usuario ya existe (volumen persistido). Iniciando sesión...")
        elif r.ok:
            print("Setup completado.")
            return r.json().get("id")
        else:
            r.raise_for_status()

    print("Iniciando sesión con credenciales existentes...")
    r = requests.post(f"{METABASE_URL}/api/session", json={
        "username": ADMIN_EMAIL,
        "password": ADMIN_PASSWORD
    }, timeout=10)
    r.raise_for_status()
    return r.json()["id"]


def get_or_create_database(token):
    headers = {"X-Metabase-Session": token}

    r = requests.get(f"{METABASE_URL}/api/database", headers=headers, timeout=10)
    for db in r.json().get("data", []):
        if db["name"] == "RetailMax DB":
            print(f"Base de datos ya existe (id={db['id']}).")
            return db["id"]

    print("Creando conexión a la base de datos PostgreSQL...")
    r = requests.post(f"{METABASE_URL}/api/database", headers=headers, json={
        "name": "RetailMax DB",
        "engine": "postgres",
        "details": {
            "host": POSTGRES_HOST,
            "port": POSTGRES_PORT,
            "dbname": POSTGRES_DB,
            "user": POSTGRES_USER,
            "password": POSTGRES_PASSWORD,
            "ssl": False,
            "tunnel-enabled": False,
            "advanced-options": False
        }
    }, timeout=30)
    if not r.ok:
        print(f"Error al crear DB ({r.status_code}): {r.text}")
        r.raise_for_status()
    db_id = r.json()["id"]
    print(f"Base de datos creada (id={db_id}).")
    return db_id


def get_existing_cards(token):
    headers = {"X-Metabase-Session": token}
    r = requests.get(f"{METABASE_URL}/api/card", headers=headers, timeout=10)
    return {c["name"]: c["id"] for c in r.json()}


def extract_name(sql_content, filename):
    first_line = sql_content.strip().splitlines()[0]
    if first_line.startswith("--"):
        return first_line.lstrip("- ").strip()
    return os.path.splitext(os.path.basename(filename))[0]


def create_cards(token, db_id):
    headers = {"X-Metabase-Session": token}
    existing = get_existing_cards(token)

    sql_files = sorted(glob.glob(os.path.join(QUERIES_PATH, "*.sql")))
    if not sql_files:
        print(f"No se encontraron archivos .sql en {QUERIES_PATH}")
        return []

    card_ids = []
    for sql_file in sql_files:
        with open(sql_file, encoding="utf-8") as f:
            content = f.read()

        name = extract_name(content, sql_file)

        if name in existing:
            print(f"  [skip] '{name}' ya existe (id={existing[name]}).")
            card_ids.append(existing[name])
            continue

        r = requests.post(f"{METABASE_URL}/api/card", headers=headers, json={
            "name": name,
            "dataset_query": {
                "type": "native",
                "native": {"query": content},
                "database": db_id
            },
            "display": "table",
            "visualization_settings": {}
        }, timeout=30)

        if r.ok:
            card_id = r.json()["id"]
            print(f"  [ok]   '{name}' creado (id={card_id}).")
            card_ids.append(card_id)
        else:
            print(f"  [err]  '{name}' falló: {r.status_code} {r.text[:200]}")

    return card_ids


def get_or_create_dashboard(token):
    headers = {"X-Metabase-Session": token}

    r = requests.get(
        f"{METABASE_URL}/api/search?q={requests.utils.quote(DASHBOARD_NAME)}&models=dashboard",
        headers=headers, timeout=10
    )
    for item in r.json().get("data", []):
        if item["name"] == DASHBOARD_NAME and item["model"] == "dashboard":
            print(f"Dashboard '{DASHBOARD_NAME}' ya existe (id={item['id']}).")
            return item["id"]

    r = requests.post(f"{METABASE_URL}/api/dashboard", headers=headers, json={
        "name": DASHBOARD_NAME
    }, timeout=30)
    r.raise_for_status()
    dash_id = r.json()["id"]
    print(f"Dashboard '{DASHBOARD_NAME}' creado (id={dash_id}).")
    return dash_id


def get_or_create_tab(token, dash_id):
    headers = {"X-Metabase-Session": token}

    r = requests.get(f"{METABASE_URL}/api/dashboard/{dash_id}", headers=headers, timeout=10)
    for tab in r.json().get("tabs", []):
        if tab["name"] == TAB_NAME:
            print(f"Tab '{TAB_NAME}' ya existe (id={tab['id']}).")
            return tab["id"]

    r = requests.post(f"{METABASE_URL}/api/dashboard/{dash_id}/tabs", headers=headers, json={
        "name": TAB_NAME
    }, timeout=30)
    if not r.ok:
        print(f"No se pudo crear tab ({r.status_code}): {r.text[:200]}. Continuando sin tab.")
        return None
    tab_id = r.json()["id"]
    print(f"Tab '{TAB_NAME}' creado (id={tab_id}).")
    return tab_id


def add_cards_to_dashboard(token, dash_id, tab_id, card_ids):
    headers = {"X-Metabase-Session": token}

    r = requests.get(f"{METABASE_URL}/api/dashboard/{dash_id}", headers=headers, timeout=10)
    existing_card_ids = {dc["card_id"] for dc in r.json().get("dashcards", [])}

    # Layout: 2 columnas, grid de 24 columnas, cada card ocupa 12 de ancho x 8 de alto
    cols = 2
    card_w, card_h = 12, 8

    added = 0
    for i, card_id in enumerate(card_ids):
        if card_id in existing_card_ids:
            print(f"  [skip] Card {card_id} ya está en el dashboard.")
            continue

        row = (i // cols) * card_h
        col = (i % cols) * card_w

        body = {
            "cardId": card_id,
            "row": row,
            "col": col,
            "size_x": card_w,
            "size_y": card_h,
            "parameter_mappings": [],
            "visualization_settings": {}
        }
        if tab_id is not None:
            body["dashboard_tab_id"] = tab_id

        r = requests.post(
            f"{METABASE_URL}/api/dashboard/{dash_id}/cards",
            headers=headers, json=body, timeout=30
        )
        if r.ok:
            print(f"  [ok]   Card {card_id} agregado (fila={row}, col={col}).")
            added += 1
        else:
            print(f"  [err]  Card {card_id}: {r.status_code} {r.text[:200]}")

    if added == 0 and not existing_card_ids:
        print("  No se agregó ningún card al dashboard.")


def main():
    wait_for_metabase()
    token = get_session_token()
    db_id = get_or_create_database(token)

    print("Creando indicadores...")
    card_ids = create_cards(token, db_id)

    if card_ids:
        print("Configurando dashboard...")
        dash_id = get_or_create_dashboard(token)
        tab_id = get_or_create_tab(token, dash_id)
        add_cards_to_dashboard(token, dash_id, tab_id, card_ids)

    print("Inicialización completada.")


if __name__ == "__main__":
    main()
