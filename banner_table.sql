CREATE TABLE banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    background_type ENUM('color', 'image') DEFAULT 'color',
    background_value VARCHAR(255) DEFAULT '#FFFFFF',
    gradient_start_color VARCHAR(20) DEFAULT '#6366F1',
    gradient_end_color VARCHAR(20) DEFAULT '#8B5CF6',
    enroll_button_text VARCHAR(50) DEFAULT 'Enroll Now',
    enroll_button_url VARCHAR(255),
    preview_button_text VARCHAR(50) DEFAULT 'Preview',
    preview_video_id VARCHAR(100),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
); 