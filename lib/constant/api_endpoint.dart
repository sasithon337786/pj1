
const String comIP = '10.160.29.168'; // <<<<<<< เปลี่ยนตรงนี้!

class ApiEndpoints {
  // กำหนด Base URL สำหรับอุปกรณ์จริง หรือเมื่อใช้ IP Address
  // ไม่ต้องใช้ conditional compilation ถ้าคุณตั้งใจจะทดสอบบนอุปกรณ์จริงเท่านั้น
  static const String baseUrl = 'http://'+comIP+'/:3000'; 
  // เพิ่ม endpoint อื่นๆ ตามต้องการ
}