# Contributing Guidelines & Git Workflow — BLOXCUBE

คู่มือนี้กำหนดระเบียบการทำงานร่วมกัน การจัดการเวอร์ชัน (Version Control) และมาตรฐานการตรวจสอบคุณภาพโค้ดก่อนนำเข้าสู่ตัวเกม **BLOXCUBE**

---

## 1. การแบ่งสายงาน Branch (Branching Strategy)

โปรเจกต์ **BLOXCUBE** ใช้โครงสร้าง Branch แยกสภาพแวดล้อมชัดเจน:

* **`main` (Production Branch):**
  - ตัวแทนของตัวเกม **BLOXCUBE** ที่เผยแพร่ให้ผู้เล่นทั่วไปเล่น (Live Game / Production Place)
  - ห้าม Push โค้ดตรงเข้า `main` เมื่ออยู่ในช่วงเปิดใช้งานจริง
  - การเปลี่ยนแปลงต้องผ่าน Pull Request จาก `develop` หรือ Hotfix ที่ผ่านการทดสอบแล้วเท่านั้น
* **`develop` (Integration / Staging Branch):**
  - ตัวแทนของตัวเกมในเซิร์ฟเวอร์ทดสอบ (Staging / Testing Place)
  - ใช้สำหรับรวมฟีเจอร์ใหม่ (เช่น ระบบคลาส, ระบบมอนสเตอร์, ระบบคราฟต์) และทดสอบความเข้ากันได้
* **Feature Branches (`feat/<feature-name>`):**
  - แตกกิ่งออกมาจาก `develop` เพื่อพัฒนาแต่ละระบบ
  - ตัวอย่าง: `feat/action-combat`, `feat/weapon-cube-customization`, `feat/class-ranger`, `feat/glider-movement`
* **Fix Branches (`fix/<bug-name>`):**
  - ใช้สำหรับแก้บั๊กของระบบ
  - ตัวอย่าง: `fix/dodge-stamina-drain`, `fix/inventory-duplication`, `fix/mob-pathfinding-stuck`

---

## 2. ข้อกำหนดการเขียน Commit (Conventional Commits)

เพื่อให้ประวัติการพัฒนาของ **BLOXCUBE** อ่านเข้าใจง่ายและสามารถนำไปสร้าง Release Notes อัตโนมัติได้ ให้ใช้รูปแบบ:

`<type>(<scope>): <short description>`

### Types ที่อนุญาต:
* `feat`: เพิ่มฟีเจอร์หรือระบบใหม่ในเกม
* `fix`: แก้ไขบั๊กหรือข้อผิดพลาด
* `refactor`: ปรับปรุงโครงสร้างโค้ดโดยไม่เปลี่ยนพฤติกรรมการเล่น
* `perf`: ปรับปรุงประสิทธิภาพ (ลด Lag, แก้ Memory Leak, ปรับปรุงการเรนเดอร์ Voxel/Mob)
* `style`: จัดหน้าตาโค้ด (Formatting / Whitespace)
* `docs`: เพิ่มหรือแก้ไขเอกสารประกอบการพัฒนา
* `chore`: งานบำรุงรักษาทั่วไป, อัปเดตแพ็กเกจ Wally, แก้ไขไฟล์ Config
* `test`: เพิ่มหรือปรับปรุงระบบ Unit Test

### ตัวอย่างสำหรับ BLOXCUBE:
```text
feat(combat): implement server-authoritative combo and charge attack
feat(crafting): add spirit cube attachment system for voxel weapons
fix(inventory): prevent item equip while player is downed
perf(mobs): optimize AI tick rate based on player distance
chore(deps): update wally packages to latest versions
```

---

## 3. มาตรฐานการเขียนโค้ดและเครื่องมือจัดหน้า (Code Quality)

1. **StyLua (Code Formatter):**
   - รันจัดหน้าโค้ดก่อนบันทึกหรือเปิด PR เสมอ (`stylua src/`)
   - ใช้ความกว้างบรรทัดมาตรฐาน (Column width 120, 4 spaces)
2. **Selene (Linter):**
   - โค้ดต้องผ่านการตรวจของ Selene (`selene src/`) โดยไม่มี Warning หรือ Error ที่ไม่ได้ประกาศข้อยกเว้นไว้
   - ห้ามปล่อยให้มีตัวแปรที่ไม่ได้ใช้งาน (Unused Variables) หรือการใช้ Global Variables โดยไม่ตั้งใจ
3. **Memory Management & Event Cleanup:**
   - ทุกครั้งที่มีการเชื่อมต่อ Event (`RBXScriptConnection`) เช่น `Humanoid.Died`, `AncestryChanged`, หรือ Hitbox/VFX ของมอนสเตอร์และผู้เล่น ต้องมั่นใจว่ามีการตัดการเชื่อมต่อ (`:Disconnect()`) หรือล้างผ่าน Cleanup/Trove เมื่อ Object ถูกทำลาย เพื่อป้องกันปัญหา Memory Leak ในเซิร์ฟเวอร์ที่เปิดเป็นเวลานาน

---

## 4. Pull Request Checklist (รายการตรวจสอบก่อน Merge โค้ด)

ก่อนจะทำการเปิดหรืออนุมัติ Pull Request เข้าสู่ **BLOXCUBE** ให้ตรวจสอบตามรายการด้านล่างนี้:

- [ ] **Anti-Exploit Verification:** โค้ดส่วนที่มีผลต่อสถานะของเกม (HP/MP/Stamina, Damage, EXP, Gold, ไอเทม, การคราฟต์) อยู่บน Server และมี Sanity Check ตรวจสอบระยะ/ความถี่ครบถ้วน
- [ ] **No Client-Side Authority:** ฝั่ง Client ไม่มีการสั่งเพิ่ม/ลดข้อมูลสเตตัสหรือไอเทมของตัวเองโดยตรง
- [ ] **Clean Output:** สคริปต์ทำงานได้ปกติ ไม่มี Error สีแดงหรือ Warning ในหน้าต่าง Output ของ Roblox Studio
- [ ] **Formatting & Linting:** ผ่านการจัดหน้าด้วย `stylua` และผ่านการตรวจของ `selene`
- [ ] **Testing:** ผ่านการทดสอบเล่นจริงบน Roblox Studio ทั้งในโหมด 1 ผู้เล่น และโหมดจำลองหลายผู้เล่น (Multiplayer Test 2+ players)
- [ ] **Documentation:** มีการบันทึกหรืออัปเดตไฟล์ Configuration (`src/shared/configs`) ที่เกี่ยวข้องหากมีการเพิ่มคลาส, สกิล, มอนสเตอร์ หรือไอเทมใหม่
