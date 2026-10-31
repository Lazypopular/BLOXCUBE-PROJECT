# BLOXCUBE — Roblox Project Standards & Development Framework

เอกสารชุดนี้เป็นโครงสร้างและมาตรฐานการพัฒนาสำหรับโปรเจกต์เกม **BLOXCUBE** บน Roblox (เกมแนว Voxel Action RPG ที่อ้างอิงจาก **Cube World** บน Steam) โดยถอดแบบแนวคิดการทำงานระดับ Enterprise (Clean Architecture, Git Workflow, Anti-Exploit Security, CI/CD Pipeline) มาปรับใช้อย่างเหมาะสมกับ Roblox Engine และภาษา Luau

---

## ภาพรวมโปรเจกต์ (Project Overview)

* **ชื่อโปรเจกต์:** BLOXCUBE (`BLOXCUBE-ROBLOX`)
* **แนวเกม (Genre):** Voxel Open-World Action RPG (Inspired by *Cube World*)
* **แกนหลักของระบบเกม (Core Pillars):**
  - **Action Combat & Classes:** ระบบต่อสู้แบบแอ็กชันเรียลไทม์ (การโจมตีปกติ, ชาร์จโจมตี, Dodge/Roll, สกิลตามสายอาชีพ เช่น Warrior, Ranger, Mage, Rogue)
  - **Voxel Weapon Customization & Crafting:** ระบบคราฟต์และติดบล็อก (Spirit Cubes / Customization Blocks) เพื่ออัปเกรดอาวุธและอุปกรณ์
  - **Exploration & Progression:** ระบบสำรวจโลกกว้าง ดันเจี้ยน บอส และระบบไอเทม/อุปกรณ์ตามระดับความหายาก (Rarity & Region/Power Scaling)
  - **Multiplayer Co-op:** เล่นร่วมกับผู้เล่นอื่นในโลกเดียวกันอย่างลื่นไหลและปลอดภัยจากโปรโกง (Server-Authoritative)

---

## สารบัญเอกสาร (Documentation Index)

1. [ARCHITECTURE.md](./ARCHITECTURE.md)
   - สถาปัตยกรรม Client-Server สำหรับระบบ Action RPG ของ **BLOXCUBE**
   - กฎความปลอดภัย "Never Trust the Client" (Anti-Exploit สำหรับ Combat, Hitbox, Loot, Crafting)
   - โครงสร้างโฟลเดอร์ตามมาตรฐาน Rojo (`src/server`, `src/client`, `src/shared`)
   - การจัดการฐานข้อมูลตัวละครและป้องกันของหายด้วย **ProfileService**
   - ข้อกำหนดการสื่อสารผ่าน Network (`RemoteEvents` / `RemoteFunctions`)

2. [CONTRIBUTING.md](./CONTRIBUTING.md)
   - โมเดล Branching (`main`, `develop`, `feat/*`, `fix/*`)
   - มาตรฐาน Conventional Commits สำหรับระบบต่างๆ ใน BLOXCUBE
   - กฎการเขียนโค้ดและมาตรฐานการจัดหน้า (**StyLua** & **Selene**)
   - Pull Request Checklist ก่อนรวมโค้ดเข้าสู่ตัวเกม

3. [TOOLCHAIN.md](./TOOLCHAIN.md)
   - รายละเอียดเครื่องมือที่ใช้ (**Foreman**, **Rojo**, **Wally**, **StyLua**, **Selene**)
   - ไฟล์ Config สำหรับโปรเจกต์ **BLOXCUBE** (`default.project.json`, `wally.toml`, `foreman.toml`, `stylua.toml`)
   - ขั้นตอนติดตั้งและเชื่อมต่อกับ Roblox Studio

4. [CI_CD.md](./CI_CD.md)
   - ระบบ Automated Quality Gate บน GitHub Actions สำหรับ **BLOXCUBE**
   - Template ไฟล์ `.github/workflows/ci.yml` ที่พร้อมใช้งานได้ทันที
