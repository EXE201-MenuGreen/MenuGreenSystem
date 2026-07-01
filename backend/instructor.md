sequenceDiagram
    autonumber
    actor Client as Client (Mobile/Web)
    participant BE as Backend (C#)
    participant AI as AI Service (FastAPI)
    participant Redis as Redis Broker
    participant Worker as Celery Worker

    Client->>BE: 1. Gửi ảnh lên phân tích món ăn
    BE->>AI: 2. Forward ảnh qua POST /api/v1/cv/analyze
    AI->>Redis: 3. Đẩy job phân tích vào hàng đợi
    AI-->>BE: 4. Trả ngay Job Response (chứa job_id, status: "queued")
    
    Note over BE, AI: Lúc này Backend đã nhận được job_id
    
    par Luồng chạy ngầm (Background Task)
        Redis->>Worker: 5a. Lấy task ra khỏi hàng đợi
        Worker->>Worker: 5b. Gọi Gemini API để nhận dạng dinh dưỡng
        Worker->>Redis: 5c. Lưu kết quả JSON cuối cùng vào Redis
    and Luồng kiểm tra của Backend (Polling)
        loop Mỗi 1.5 - 2 giây
            BE->>AI: 6a. GET /api/v1/cv/jobs/{job_id}
            AI->>Redis: 6b. Kiểm tra trạng thái tác vụ
            AI-->>BE: 6c. Trả về status ("processing" hoặc "done" kèm kết quả)
        end
    end

    Note over BE: Khi nhận được status = "done" cùng kết quả phân tích
    BE->>BE: 7. Lưu kết quả vào DB backend, xử lý business logic
    BE-->>Client: 8. Trả về thông tin món ăn & dinh dưỡng hoàn chỉnh cho người dùng
