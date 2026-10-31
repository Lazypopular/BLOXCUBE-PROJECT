# Software Architecture & Security Contract — BLOXCUBE

เอกสารนี้ระบุมาตรฐานสถาปัตยกรรมซอฟต์แวร์และการจัดการความปลอดภัยสำหรับการพัฒนาเกม **BLOXCUBE** (Voxel Action RPG อ้างอิงจาก *Cube World*) บน Roblox Engine โดยยึดหลักความเสถียรและความปลอดภัยจากการถูกเจาะ/โกง (Anti-Exploit)

---

## 1. ปรัชญาหลัก: "Never Trust the Client" (ความปลอดภัยเป็นอันดับหนึ่ง)

เนื่องจาก **BLOXCUBE** เป็นเกมแนว Action RPG ที่มีระบบการต่อสู้เรียลไทม์, ดรอปไอเทม, คราฟต์อาวุธ และระบบเลเวล/สเตตัส ซึ่งเครื่องของผู้เล่น (Client) สามารถถูกใช้ Script Executor ดัดแปลงค่าได้ จึงต้องปฏิบัติตามกฎเหล็กดังนี้:

1. **Client ขอได้แค่ "ความต้องการ" (Intent):**
   - **การต่อสู้/ใช้สกิล:** ผู้เล่นคลิกโจมตีหรือกดปุ่มสกิล -> Client ส่งคำขอ เช่น `RequestAttack(attackType, aimDirection)` หรือ `RequestUseSkill(skillSlot)` ไปยัง Server (พร้อมเล่นแอนิเมชันล่วงหน้าฝั่ง Client เพื่อให้รู้สึกตอบสนองไว)
   - **การเก็บของ/คราฟต์:** ผู้เล่นกดเก็บ Loot หรือติดบล็อกอัปเกรดอาวุธ -> Client ส่ง `RequestPickupLoot(lootId)` หรือ `RequestAttachCube(weaponUid, cubeItemId, voxelCoord)`
   - Client **ห้าม** ส่งค่าความเสียหาย (Damage), ค่าสเตตัส, หรือสั่งเสกไอเทมมาเอง เช่น ห้ามส่ง `DealDamage(mob, 9999)` หรือ `AddGold(50000)`
2. **Server เป็นผู้ "ตรวจสอบและตัดสินใจ" (Authority & Validation):**
   - **Sanity & Distance Check:**
     - ตรวจสอบระยะโจมตี (Hitbox / Range Validation) ว่าตัวละครผู้เล่นอยู่ในระยะอาวุธถึงเป้าหมายจริงหรือไม่
     - ตรวจสอบระยะเก็บ Loot, คุยกับ NPC, หรือโต๊ะคราฟต์ (Crafting Anvil / Customization Bench) ว่าอยู่ใกล้จริง (ป้องกันการวาร์ปเก็บของข้ามแมพ)
   - **Cooldown / Stamina / MP & Rate Limiting:**
     - ตรวจสอบ Cooldown ของท่าโจมตี, การกลิ้งหลบ (Dodge Roll), และค่า Stamina/Mana จาก Memory ฝั่ง Server เสมอ
     - จำกัดความถี่ในการยิง RemoteEvent ป้องกันการสแปมคำขอทำให้เซิร์ฟเวอร์ค้าง
   - **State / Ownership Check:**
     - ตรวจสอบว่าผู้เล่นมีคลาส (Warrior, Ranger, Mage, Rogue), เลเวล, วัตถุดิบคราฟต์ หรือไอเทมชิ้นนั้นอยู่ใน Inventory จริงหรือไม่จาก Memory ฝั่ง Server
3. **Server เป็นผู้ "บันทึกและกระจายผล" (Replication & Persistence):**
   - เมื่อ Server คำนวณ Damage, ตัดสินการติด Critical/Stun, หักวัตถุดิบ หรือดรอปไอเทมเสร็จสิ้น จึงอัปเดตสถานะใน Memory/DataStore และส่งสัญญาณกลับไปให้ Client ทุกเครื่องในบริเวณนั้นแสดงเอฟเฟกต์ตัวเลขดาเมจ, แอนิเมชัน หรืออัปเดต UI

---

## 2. โครงสร้างโฟลเดอร์ของโปรเจกต์ (Project Directory Layout)

โครงสร้างโฟลเดอร์ของ **BLOXCUBE** แยกขอบเขตความรับผิดชอบ (Separation of Concerns) ตามมาตรฐาน Rojo ดังนี้:

```text
src/
├── server/                     # [ServerScriptService] โค้ดที่รันเฉพาะบน Server เท่านั้น
│   ├── init.server.luau        # Entry point เริ่มต้นของ Server (Bootstrap Services)
│   ├── services/               # Core Game Services
│   │   ├── DataService.luau    # จัดการข้อมูลผู้เล่นผ่าน ProfileService
│   │   ├── PlayerService.luau  # จัดการตัวละคร, คลาสอาชีพ, สเตตัส, เลเวล
│   │   ├── CombatService.luau  # คำนวณ Hitbox, Damage, Stamina, Dodge, Skill
│   │   ├── InventoryService.luau # จัดการกระเป๋า, สวมใส่อุปกรณ์, คราฟต์ & อัปเกรดอาวุธ
│   │   ├── MobService.luau     # จัดการ AI มอนสเตอร์, บอส, และการเกิด (Spawning)
│   │   └── LootService.luau    # จัดการการดรอปของและการสุ่ม Rarity
│   ├── handlers/               # ตัวรับสัญญาณ RemoteEvent/RemoteFunction และทำ Sanity Check
│   └── components/             # พฤติกรรมของ Object ในโลกฝั่ง Server (เช่น โต๊ะคราฟต์, แร่, จุดวาร์ป)
│
├── client/                     # [StarterPlayerScripts] โค้ดที่รันบนเครื่องผู้เล่นเท่านั้น
│   ├── init.client.luau        # Entry point เริ่มต้นของ Client (Bootstrap Controllers)
│   ├── controllers/            # ตัวควบคุมฝั่ง Client
│   │   ├── InputController.luau    # รับปุ่มโจมตี, Dodge, สกิล, เปิดกระเป๋า
│   │   ├── CameraController.luau   # มุมกล้อง Action RPG (Third-Person / Mouse Lock)
│   │   ├── CombatController.luau   # แอนิเมชันการโจมตี, VFX, เลขดาเมจฝั่งผู้เล่น
│   │   └── MovementController.luau # การเคลื่อนที่พิเศษ (Dodge Roll, Glider, ปีนป่าย)
│   └── ui/                     # การจัดการ User Interface (HP/MP/Stamina Bar, Inventory, Crafting UI, Minimap)
│
└── shared/                     # [ReplicatedStorage] โค้ดและข้อมูลที่ทั้ง Server และ Client ใช้งานร่วมกัน
    ├── configs/                # ค่าคงที่, ข้อมูลคลาสอาชีพ, ตารางไอเทม, สูตรคราฟต์, สเตตัสมอนสเตอร์
    ├── modules/                # Utilities, สูตรคำนวณพื้นฐาน, Helper functions ที่ไม่มี Side Effect
    └── network/                # รายชื่อ RemoteEvents/RemoteFunctions ที่ขึ้นทะเบียนไว้
```

---

## 3. การจัดการฐานข้อมูลและการเซฟข้อมูล (Data Persistence with ProfileService)

ห้ามใช้ `DataStoreService` ดิบโดยตรงสำหรับข้อมูลตัวละครของ **BLOXCUBE** เพราะอาจเกิดปัญหา **Data Loss** เมื่อเซิร์ฟเวอร์ปิดตัวกะทันหัน หรือเกิดปัญหา **Item Duplication** (ปั๊มของ/อาวุธ) เมื่อผู้เล่นสลับเซิร์ฟเวอร์รวดเร็ว

### มาตรฐานการจัดเก็บข้อมูลของ BLOXCUBE:
1. **ใช้ ProfileService (Session Locking):**
   - เมื่อผู้เล่นเข้าเซิร์ฟเวอร์ -> โหลดและทำการ **Lock Profile** เพื่อไม่ให้เซิร์ฟเวอร์อื่นเขียนข้อมูลทับ
   - ระหว่างเล่นเกม -> แก้ไขข้อมูล (EXP, Gold, Inventory, Equipped Gear, Weapon Customization Cubes) ในตัวแปรบน Server Memory เท่านั้น
   - เมื่อผู้เล่นออกจากเกม หรือเซิร์ฟเวอร์ปิดตัว (`BindToClose`) -> ทำการ Save และ **Release Lock**
2. **Auto-Saving:** มีระบบบันทึกข้อมูลเป็นรอบอัตโนมัติของ ProfileService
3. **Data Schema Migration:**
   - โครงสร้าง Data Template ของตัวละคร (เช่น `Class`, `Level`, `Exp`, `Gold`, `Inventory`, `Equipment`, `UnlockedRegions`) ต้องมีค่า Default เสมอ
   - ใช้ `Profile:Reconcile()` เพื่อเติมฟิลด์ใหม่ให้แก่ผู้เล่นเก่าเมื่อเกมอัปเดตระบบใหม่โดยที่ข้อมูลเดิมไม่เสียหาย

---

## 4. ข้อตกลงการสื่อสารผ่าน Network (Networking Contract)

1. **RemoteEvent (One-Way Communication):**
   - ใช้สำหรับการแจ้งเตือนหรือสั่งการที่ไม่ต้องรอผลลัพธ์ย้อนกลับ (เช่น การกดโจมตี, การกลิ้งหลบ, การส่งสัญญาณแสดง VFX)
   - จาก Client -> Server: มี `player: Player` เป็น Parameter ตัวแรกเสมอ
   - จาก Server -> Client: ส่งเพื่อสั่งให้ Client เล่นเอฟเฟกต์หรืออัปเดต UI
2. **RemoteFunction (Request-Response):**
   - **ใช้เฉพาะทิศทาง Client เรียก Server เท่านั้น** (Client -> Server) เช่น ขอข้อมูลเริ่มต้นหรือการกดคราฟต์ที่ต้องการคำตอบสำเร็จ/ล้มเหลว
   - **ห้ามเด็ดขาด:** ห้าม Server เรียก `RemoteFunction:InvokeClient()` ไปยังเครื่องผู้เล่น เพราะหาก Client ถูกดัดแปลงหรือค้าง จะทำให้เธรดของ Server ค้างตามไปด้วย (Infinite Hang)
3. **Payload Sanitization:**
   - ตรวจสอบ `typeof()` ของ Parameter ทุกตัวที่ส่งมาจาก Client เสมอ
   - ป้องกันการส่งค่า `NaN` (`value ~= value`), `math.huge`, Vector3 ที่ผิดปกติ หรือ String ขนาดยักษ์มาทำให้ระบบล่ม
