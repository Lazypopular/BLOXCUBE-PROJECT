# Modern Roblox Toolchain & Project Configuration — BLOXCUBE

เอกสารนี้อธิบายชุดเครื่องมือสำหรับการพัฒนาโปรเจกต์ **BLOXCUBE** แบบ File-based ร่วมกับ VS Code, Git และ Roblox Studio

---

## 1. รายชื่อเครื่องมือหลัก (Core Tools)

| เครื่องมือ | หน้าที่ | คำอธิบาย |
|---|---|---|
| **Foreman** | Toolchain Manager | ตัวจัดการเวอร์ชันของเครื่องมือทั้งหมด (คล้าย nvm / asdf) |
| **Rojo** | Live Sync Tool | ซิงค์ไฟล์โค้ดและ Assets ของ BLOXCUBE จากโฟลเดอร์ในคอมพิวเตอร์เข้าสู่ Roblox Studio แบบเรียลไทม์ |
| **Wally** | Package Manager | ตัวจัดการ Library ภายนอก (เช่น ProfileService, Promise, Signal) |
| **StyLua** | Code Formatter | จัดระเบียบและหน้าตาโค้ด Luau ให้อัตโนมัติและเป็นระเบียบตามมาตรฐาน |
| **Selene** | Static Analyzer / Linter | ตรวจจับข้อผิดพลาดเชิงโครงสร้าง โค้ดที่ไม่ปลอดภัย หรือตัวแปรลอย |

---

## 2. ไฟล์ Configuration ในโปรเจกต์ BLOXCUBE

### 2.1 `foreman.toml` (ล็อกเวอร์ชันของเครื่องมือ)
```toml
[tools]
rojo = { source = "rojo-rbx/rojo", version = "7.4.4" }
wally = { source = "UpliftGames/wally", version = "0.3.2" }
stylua = { source = "JohnnyMorganz/StyLua", version = "2.0.2" }
selene = { source = "Kampfkarren/selene", version = "0.27.1" }
```

### 2.2 `default.project.json` (โครงสร้างการ Map ไฟล์เข้า Roblox DataModel)
```json
{
  "name": "BLOXCUBE",
  "tree": {
    "$className": "DataModel",

    "ServerScriptService": {
      "$path": "src/server"
    },

    "StarterPlayer": {
      "StarterPlayerScripts": {
        "$path": "src/client"
      }
    },

    "ReplicatedStorage": {
      "$path": "src/shared",
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

### 2.3 `wally.toml` (การจัดการ Dependencies)
```toml
[package]
name = "lazypopular/bloxcube"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
ProfileService = "madstudioroblox/profileservice@^1.4.2"
Promise = "evaera/promise@^4.0.0"
Signal = "sleitnick/signal@^2.0.1"
```

### 2.4 `stylua.toml` (การตั้งค่าจัดหน้าโค้ด)
```toml
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

---

## 3. ขั้นตอนการเริ่มต้นใช้งานครั้งแรก (Quickstart Workflow)

1. **ติดตั้งเครื่องมือผ่าน Foreman:**
   ```bash
   foreman install
   ```
2. **ดาวน์โหลด Packages ที่กำหนดไว้ใน Wally:**
   ```bash
   wally install
   # แปลง Sourcemap สำหรับแพ็กเกจ
   rojo sourcemap default.project.json --output sourcemap.json
   ```
3. **เริ่ม Sync เข้าสู่ Roblox Studio:**
   ```bash
   rojo serve default.project.json
   ```
4. **เปิด Roblox Studio:**
   - เปิดแมพ **BLOXCUBE**
   - เปิด Plugin **Rojo** ในแถบ Plugins
   - กดปุ่ม **Connect** (พอร์ตมาตรฐาน `localhost:34872`)
   - โค้ดทั้งหมดจะปรากฏใน Explorer ของ Roblox Studio ทันที
