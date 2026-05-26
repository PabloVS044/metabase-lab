import glob
import os
import re
import time
from pathlib import Path

import requests

METABASE_URL = os.getenv("METABASE_URL", "http://retailmax_metabase:3000")
ADMIN_EMAIL = os.getenv("MB_ADMIN_EMAIL", "calificar@uvg.edu.gt")
ADMIN_PASSWORD = os.getenv("MB_ADMIN_PASSWORD", "secret123+")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "retailmax_postgres")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.getenv("POSTGRES_DB", "retailmax_db")
POSTGRES_USER = os.getenv("POSTGRES_USER", "retailmax")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "retailmax123")
QUERIES_PATH = os.getenv("QUERIES_PATH", "/queries")
DASHBOARD_NAME = os.getenv("DASHBOARD_NAME", "RetailMax - Finanzas")
TAB_ONE_NAME = os.getenv("TAB_ONE_NAME", "Rentabilidad Comercial")
TAB_TWO_NAME = os.getenv("TAB_TWO_NAME", "Control Financiero")

CARD_CONFIG = {
    1: {"display": "table", "tab": 1},
    2: {
        "display": "bar",
        "tab": 1,
        "visualization_settings": {
            "graph.dimensions": ["tienda"],
            "graph.metrics": ["monto_descuentos", "monto_reembolsos", "perdida_total"],
            "graph.x_axis.scale": "ordinal",
        },
    },
    3: {
        "display": "bar",
        "tab": 1,
        "visualization_settings": {
            "graph.dimensions": ["tienda"],
            "graph.metrics": ["ingresos_totales", "costos_totales", "margen_neto"],
            "graph.x_axis.scale": "ordinal",
        },
    },
    4: {
        "display": "line",
        "tab": 1,
        "visualization_settings": {
            "graph.dimensions": ["mes", "region"],
            "graph.metrics": ["margen_porcentaje"],
            "graph.x_axis.scale": "ordinal",
        },
    },
    5: {"display": "bar", "tab": 1},
    6: {"display": "table", "tab": 1},
    7: {
        "display": "pie",
        "tab": 2,
        "visualization_settings": {
            "pie.dimension": "metodo_pago",
            "pie.metric": "monto_total",
            "graph.metrics": ["monto_total"],
        },
    },
    8: {"display": "bar", "tab": 2},
    9: {"display": "line", "tab": 2},
    10: {
        "display": "bar",
        "tab": 2,
        "visualization_settings": {
            "graph.dimensions": ["categoria"],
            "graph.metrics": ["capital_inmovilizado_costo", "valor_venta_potencial"],
            "graph.x_axis.scale": "ordinal",
        },
    },
    11: {
        "display": "bar",
        "tab": 2,
        "visualization_settings": {
            "graph.dimensions": ["motivo"],
            "graph.metrics": ["total_reembolsado", "reembolso_promedio"],
            "graph.x_axis.scale": "ordinal",
        },
    },
    12: {"display": "table", "tab": 2},
}


def wait_for_metabase():
    print("Esperando que Metabase este listo...")
    for _ in range(72):
        try:
            response = requests.get(f"{METABASE_URL}/api/health", timeout=5)
            if response.ok and response.json().get("status") == "ok":
                print("Metabase listo.")
                return
        except Exception:
            pass
        time.sleep(5)
    raise RuntimeError("Metabase no respondio a tiempo.")


def get_session_token():
    response = requests.get(f"{METABASE_URL}/api/session/properties", timeout=10)
    response.raise_for_status()
    props = response.json()

    setup_token = props.get("setup-token")
    if setup_token:
        print("Ejecutando setup inicial de Metabase...")
        response = requests.post(
            f"{METABASE_URL}/api/setup",
            json={
                "token": setup_token,
                "user": {
                    "email": ADMIN_EMAIL,
                    "password": ADMIN_PASSWORD,
                    "first_name": "Calificar",
                    "last_name": "UVG",
                    "site_name": "RetailMax",
                },
                "prefs": {
                    "site_name": "RetailMax",
                    "allow_tracking": False,
                },
            },
            timeout=30,
        )
        if response.ok:
            print("Setup completado.")
            return response.json()["id"]
        if response.status_code != 403:
            response.raise_for_status()
        print("Setup ya aplicado previamente. Intentando login...")

    response = requests.post(
        f"{METABASE_URL}/api/session",
        json={"username": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        timeout=10,
    )
    response.raise_for_status()
    print(f"Sesion iniciada con {ADMIN_EMAIL}.")
    return response.json()["id"]


def get_or_create_database(token):
    headers = {"X-Metabase-Session": token}
    for attempt in range(1, 6):
        response = requests.get(f"{METABASE_URL}/api/database", headers=headers, timeout=10)
        response.raise_for_status()

        for db in response.json().get("data", []):
            if db["name"] == "RetailMax DB":
                print(f"Base de datos ya existe (id={db['id']}).")
                return db["id"]

        print(f"Creando conexion a PostgreSQL (intento {attempt}/5)...")
        response = requests.post(
            f"{METABASE_URL}/api/database",
            headers=headers,
            json={
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
                    "advanced-options": False,
                },
            },
            timeout=30,
        )
        if response.ok:
            db_id = response.json()["id"]
            print(f"Base de datos creada (id={db_id}).")
            return db_id

        print(f"Metabase rechazo la conexion ({response.status_code}): {response.text[:300]}")
        time.sleep(5)

    response.raise_for_status()


def parse_indicator_number(path):
    match = re.search(r"indicador\((\d+)\)\.sql$", path.name)
    if not match:
        raise ValueError(f"No se pudo determinar el numero del indicador para {path}")
    return int(match.group(1))


def clean_comment_line(line):
    return line.lstrip("- ").strip()


def extract_name(sql_content, filename):
    for line in sql_content.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("--"):
            name = clean_comment_line(stripped)
            name = re.sub(r"^Tab\s+\d+,\s*", "", name, flags=re.IGNORECASE)
            return name
        break
    return Path(filename).stem


def extract_description(sql_content):
    description_lines = []
    for line in sql_content.splitlines()[1:]:
        stripped = line.strip()
        if not stripped.startswith("--"):
            break
        description_lines.append(clean_comment_line(stripped))
    return " ".join(description_lines)


def load_indicator_specs():
    specs = []
    for path_str in glob.glob(os.path.join(QUERIES_PATH, "indicador(*).sql")):
        path = Path(path_str)
        indicator_number = parse_indicator_number(path)
        with open(path, encoding="utf-8") as file:
            content = file.read().strip()

        config = CARD_CONFIG.get(indicator_number, {"display": "table", "tab": 1})
        specs.append(
            {
                "number": indicator_number,
                "path": str(path),
                "name": extract_name(content, path.name),
                "description": extract_description(content),
                "sql": content,
                "display": config["display"],
                "visualization_settings": config.get("visualization_settings", {}),
                "tab": TAB_ONE_NAME if config["tab"] == 1 else TAB_TWO_NAME,
            }
        )

    specs.sort(key=lambda item: item["number"])
    if len(specs) < 12:
        raise RuntimeError(
            f"Se esperaban al menos 12 indicadores y solo se encontraron {len(specs)}."
        )
    return specs


def get_existing_cards(token):
    headers = {"X-Metabase-Session": token}
    response = requests.get(f"{METABASE_URL}/api/card", headers=headers, timeout=10)
    response.raise_for_status()
    return {card["name"]: card for card in response.json()}


def upsert_cards(token, db_id, specs):
    headers = {"X-Metabase-Session": token}
    existing_cards = get_existing_cards(token)
    card_specs = []

    for spec in specs:
        payload = {
            "name": spec["name"],
            "dataset_query": {
                "type": "native",
                "native": {"query": spec["sql"]},
                "database": db_id,
            },
            "display": spec["display"],
            "visualization_settings": spec["visualization_settings"],
        }
        if spec["description"]:
            payload["description"] = spec["description"]

        existing = existing_cards.get(spec["name"])
        if existing:
            response = requests.put(
                f"{METABASE_URL}/api/card/{existing['id']}",
                headers=headers,
                json=payload,
                timeout=30,
            )
            if not response.ok:
                print(
                    f"  [error] No se pudo actualizar '{spec['name']}' "
                    f"({response.status_code}): {response.text[:500]}"
                )
            response.raise_for_status()
            card_id = existing["id"]
            print(f"  [update] '{spec['name']}' (id={card_id}).")
        else:
            response = requests.post(
                f"{METABASE_URL}/api/card",
                headers=headers,
                json=payload,
                timeout=30,
            )
            if not response.ok:
                print(
                    f"  [error] No se pudo crear '{spec['name']}' "
                    f"({response.status_code}): {response.text[:500]}"
                )
            response.raise_for_status()
            card_id = response.json()["id"]
            print(f"  [create] '{spec['name']}' (id={card_id}).")

        card_specs.append({**spec, "card_id": card_id})

    return card_specs


def get_or_create_dashboard(token):
    headers = {"X-Metabase-Session": token}
    response = requests.get(
        f"{METABASE_URL}/api/search?q={requests.utils.quote(DASHBOARD_NAME)}&models=dashboard",
        headers=headers,
        timeout=10,
    )
    response.raise_for_status()
    for item in response.json().get("data", []):
        if item["name"] == DASHBOARD_NAME and item["model"] == "dashboard":
            print(f"Dashboard '{DASHBOARD_NAME}' ya existe (id={item['id']}).")
            return item["id"]

    response = requests.post(
        f"{METABASE_URL}/api/dashboard",
        headers=headers,
        json={"name": DASHBOARD_NAME, "description": "Dashboard financiero de RetailMax"},
        timeout=30,
    )
    response.raise_for_status()
    dashboard_id = response.json()["id"]
    print(f"Dashboard '{DASHBOARD_NAME}' creado (id={dashboard_id}).")
    return dashboard_id


def get_dashboard(token, dashboard_id):
    headers = {"X-Metabase-Session": token}
    response = requests.get(
        f"{METABASE_URL}/api/dashboard/{dashboard_id}", headers=headers, timeout=10
    )
    response.raise_for_status()
    return response.json()


def sync_dashboard_layout(token, dashboard_id, card_specs):
    headers = {"X-Metabase-Session": token}
    dashboard = get_dashboard(token, dashboard_id)
    existing_dashcards = {dashcard["card_id"]: dashcard for dashcard in dashboard.get("dashcards", [])}
    existing_tabs = {tab["name"]: tab["id"] for tab in dashboard.get("tabs", [])}

    if (
        TAB_ONE_NAME in existing_tabs
        and TAB_TWO_NAME in existing_tabs
        and all(spec["card_id"] in existing_dashcards for spec in card_specs)
    ):
        print("Dashboard ya tiene tabs y tarjetas configuradas.")
        return

    tabs_payload = []
    temporary_tab_ids = {}
    next_temp_tab_id = -1
    for tab_name in (TAB_ONE_NAME, TAB_TWO_NAME):
        if tab_name in existing_tabs:
            tabs_payload.append({"id": existing_tabs[tab_name], "name": tab_name})
            continue
        temporary_tab_ids[tab_name] = next_temp_tab_id
        tabs_payload.append({"id": next_temp_tab_id, "name": tab_name})
        print(f"Tab '{tab_name}' sera creado (temp_id={next_temp_tab_id}).")
        next_temp_tab_id -= 1

    def resolve_tab_id(tab_name):
        return existing_tabs.get(tab_name, temporary_tab_ids[tab_name])

    cards_payload = []
    card_w, card_h = 12, 8
    tab_offsets = {TAB_ONE_NAME: 0, TAB_TWO_NAME: 0}

    for spec in card_specs:
        index_in_tab = tab_offsets[spec["tab"]]
        row = (index_in_tab // 2) * card_h
        col = (index_in_tab % 2) * card_w
        tab_offsets[spec["tab"]] += 1

        existing_dashcard = existing_dashcards.get(spec["card_id"])
        cards_payload.append(
            {
                "id": existing_dashcard["id"] if existing_dashcard else -(100 + spec["number"]),
                "card_id": spec["card_id"],
                "row": row,
                "col": col,
                "size_x": card_w,
                "size_y": card_h,
                "parameter_mappings": existing_dashcard.get("parameter_mappings", []) if existing_dashcard else [],
                "visualization_settings": existing_dashcard.get("visualization_settings", {}) if existing_dashcard else {},
                "dashboard_tab_id": resolve_tab_id(spec["tab"]),
            }
        )

    response = requests.put(
        f"{METABASE_URL}/api/dashboard/{dashboard_id}/cards",
        headers=headers,
        json={"cards": cards_payload, "tabs": tabs_payload},
        timeout=30,
    )
    if not response.ok:
        print(
            f"No se pudo sincronizar el layout del dashboard "
            f"({response.status_code}): {response.text[:500]}"
        )
    response.raise_for_status()
    print("Tabs y tarjetas sincronizados en el dashboard.")


def main():
    wait_for_metabase()
    token = get_session_token()
    db_id = get_or_create_database(token)

    print("Cargando indicadores...")
    specs = load_indicator_specs()
    card_specs = upsert_cards(token, db_id, specs)

    print("Configurando dashboard...")
    dashboard_id = get_or_create_dashboard(token)
    sync_dashboard_layout(token, dashboard_id, card_specs)
    print("Inicializacion completada.")


if __name__ == "__main__":
    main()
