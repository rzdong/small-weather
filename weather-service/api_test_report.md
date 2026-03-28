# Go Weather Service API Test Report

**Test Date:** 2026-03-25  
**Service URL:** `http://localhost:3001`  
**Target Proxy:** QWeather API (https://pf5vxbpy5n.re.qweatherapi.com)

---

## 1. Geo City Lookup
**Endpoint:** `GET /api/weather/geo/lookup?location=beijing`

### Request Summary
- **Method:** GET
- **Params:** `location=beijing`
- **Result:** Success (200 OK)

### Response Data (Partial)
```json
{
    "code": "200",
    "location": [
        {
            "name": "北京",
            "id": "101010100",
            "adm2": "北京",
            "adm1": "北京市",
            "country": "中国",
            "type": "city"
        }
    ]
}
```

---

## 2. Top Cities
**Endpoint:** `GET /api/weather/geo/top`

### Request Summary
- **Method:** GET
- **Result:** Success (200 OK)

### Response Data (Partial)
```json
{
    "code": "200",
    "topCityList": [
        { "name": "北京", "id": "101010100" },
        { "name": "余杭", "id": "101210106" },
        { "name": "朝阳", "id": "101010300" }
    ]
}
```

---

## 3. Weather Now
**Endpoint:** `GET /api/weather/now?location=101010100`

### Request Summary
- **Method:** GET
- **Params:** `location=101010100` (Beijing)
- **Result:** Success (200 OK)

### Current Weather Snapshot
- **Update Time:** 2026-03-25 22:04
- **Temp:** 14°C
- **Text:** 霾 (Haze)
- **Humidity:** 52%
- **Wind:** 东北风 (NE Wind), Scale 1

---

## 4. Hourly Forecast (24h)
**Endpoint:** `GET /api/weather/24h?location=101010100`

### Request Summary
- **Method:** GET
- **Params:** `location=101010100`
- **Result:** Success (200 OK)

### Next few hours forecast:
- **23:00:** 14°C, 晴 (Sunny)
- **00:00:** 14°C, 晴 (Sunny)
- **01:00:** 13°C, 晴 (Sunny)

---

## 5. Daily Forecast (7d)
**Endpoint:** `GET /api/weather/7d?location=101010100`

### Request Summary
- **Method:** GET
- **Params:** `location=101010100`
- **Result:** Success (200 OK)

### Forecast Summary:
- **2026-03-25:** Max 24°C, Min 10°C, 晴
- **2026-03-26:** Max 25°C, Min 10°C, 多云
- **2026-03-27:** Max 21°C, Min 9°C, 多云

---

## Overall Status
**PASS** - All weather proxy endpoints are responding correctly with valid data from the upstream QWeather API.
