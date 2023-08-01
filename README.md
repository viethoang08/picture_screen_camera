# picture_screen_camera


## Getting Started


PictureScreenCamera({ shootingTime, lensDirection, examId, timeRunService });

- examId: bắt buộc phải có mã đề thi (String).
- shootingTimeSeconds: Khoảng thời giản chụp ảnh cách nhau được tính bằng giây (int).
- shootingTimeMinutes: Khoảng thời giản chụp ảnh cách nhau được tính bằng phút (int).
- changeCameraSeconds: Khoảng thời giản đổi camera cách nhau được tính bằng giây (int).
- changeCameraMinutes: Khoảng thời giản đổi camera cách nhau được tính bằng phút (int).
- lensDirection: 0 camera sau, 1 camera trước (int) còn lại là cả 2.

In class ServicePictureScreenCamera
- getListPathImageByExamId(examId) để lấy danh sách đường dẫn tới ảnh màn hình của đề
