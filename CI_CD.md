# Continuous Integration (CI) Pipeline — BLOXCUBE

เอกสารนี้ระบุการทำงานของระบบตรวจสอบคุณภาพโค้ดอัตโนมัติ (Automated Quality Gate) สำหรับโปรเจกต์ **BLOXCUBE** โดยใช้ GitHub Actions เพื่อรับประกันว่าโค้ดทุกชุดที่จะถูกนำเข้าสู่ Branch หลัก (`main` และ `develop`) มีความถูกต้องและสามารถ Build เป็นไฟล์แมพของ Roblox (`build/BLOXCUBE.rbxl`) ได้จริง

---

## 1. ลำดับการตรวจสอบใน Pipeline (Pipeline Stages)

ทุกครั้งที่มีการเปิด Pull Request หรือ Push โค้ดเข้า `main` และ `develop` ระบบ CI จะทำงานตามลำดับดังนี้:

```text
[Push / Pull Request]
       │
       ▼
 1. Checkout โค้ด
       │
       ▼
 2. StyLua Check (ตรวจสอบว่าจัดหน้าตาโค้ดถูกต้องหรือไม่)
       │
       ▼
 3. Selene Lint (ตรวจสอบหาข้อผิดพลาด Syntax และตัวแปรผิดปกติ)
       │
       ▼
 4. Rojo Build Test (ทดสอบประกอบไฟล์เกมจริง build/BLOXCUBE.rbxl)
       │
       ▼
[ ผ่านการตรวจสอบ / Ready to Merge ]
```

---

## 2. ไฟล์การตั้งค่า GitHub Actions

บันทึกไฟล์นี้ไว้ที่ตำแหน่ง `.github/workflows/ci.yml`:

```yaml
name: BLOXCUBE Quality Gate

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

jobs:
  validate:
    name: Lint, Format & Build Verification
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      # ขั้นตอนที่ 1: ตรวจสอบการจัดหน้าโค้ด
      - name: Check Code Formatting (StyLua)
        uses: JohnnyMorganz/stylua-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          args: --check src/

      # ขั้นตอนที่ 2: ตรวจสอบ Static Code Analysis
      - name: Lint Code (Selene)
        uses: Kampfkarren/selene-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          args: src/

      # ขั้นตอนที่ 3: ติดตั้ง Foreman และเครื่องมือ
      - name: Setup Foreman Tools
        uses: Roblox/setup-foreman@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          allow-external-github-orgs: true

      # ขั้นตอนที่ 4: ทดสอบประกอบเป็นไฟล์แมพ Roblox
      - name: Verify Rojo Build
        run: |
          mkdir -p build
          rojo build default.project.json --output build/BLOXCUBE.rbxl

      # ขั้นตอนที่ 5: เก็บ Artifact ไฟล์แมพที่ Build ได้ (เก็บไว้ตรวจสอบ 7 วัน)
      - name: Upload Built Place File
        uses: actions/upload-artifact@v4
        with:
          name: bloxcube-compiled-place
          path: build/BLOXCUBE.rbxl
          retention-days: 7
```

---

## 3. การขยายผลสู่ Automated Deployment (สำหรับอนาคต)

เมื่อพร้อมเปิดเซิร์ฟเวอร์ทดสอบหรือเกมจริง สามารถเพิ่ม Job สำหรับการ Publish แมพ **BLOXCUBE** ขึ้น Roblox โดยอัตโนมัติได้โดยใช้ **Roblox Open Cloud API**:
- เมื่อ Merge เข้า `develop` -> อัปโหลดไฟล์ `.rbxl` ไปยัง Place ID ของเซิร์ฟเวอร์ทดสอบ (Staging Place)
- เมื่อ Merge เข้า `main` -> อัปโหลดและสั่ง Publish ไปยัง Place ID ของเกมจริง (Production Place)
- สิ่งที่ต้องเตรียม: `UNIVERSE_ID`, `PLACE_ID`, และ `ROBLOX_OPEN_CLOUD_API_KEY` (ใส่ไว้ใน GitHub Secrets)
