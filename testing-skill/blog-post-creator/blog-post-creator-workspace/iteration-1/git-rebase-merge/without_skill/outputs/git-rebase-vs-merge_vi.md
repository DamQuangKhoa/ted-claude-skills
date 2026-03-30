# Git Rebase vs Merge: Lựa Chọn Chiến Lược Phù Hợp Cho Quy Trình Làm Việc

Khi làm việc với Git, một trong những câu hỏi thường gặp nhất mà developers phải đối mặt là quyết định giữa `git rebase` và `git merge`. Cả hai lệnh đều tích hợp thay đổi từ branch này sang branch khác, nhưng chúng thực hiện theo những cách hoàn toàn khác nhau. Hiểu rõ những điểm khác biệt này là rất quan trọng để duy trì một codebase sạch và dễ quản lý.

## Sự Khác Biệt Cơ Bản

### Git Merge: Lựa Chọn An Toàn

Khi bạn chạy `git merge`, Git tạo ra một **merge commit** mới để kết nối lịch sử của hai branch lại với nhau. Commit này có hai parent commits, giữ nguyên hoàn toàn lịch sử của cả hai branch đúng như cách chúng đã xảy ra.

```bash
git checkout main
git merge feature-branch
```

Cách tiếp cận này duy trì toàn bộ context về thời điểm và cách thức các thay đổi được tích hợp, giúp dễ dàng nhìn thấy câu chuyện đầy đủ về sự phát triển của dự án.

### Git Rebase: Người Viết Lại Lịch Sử

Ngược lại, `git rebase` **viết lại lịch sử**. Nó lấy các commits của bạn từ một branch và replay chúng lên trên một branch khác, tạo ra các commits hoàn toàn mới với SHA hashes khác nhau.

```bash
git checkout feature-branch
git rebase main
```

Kết quả? Một **lịch sử tuyến tính** trông giống như tất cả công việc của bạn đã diễn ra tuần tự, commit này sau commit kia, không có sự phức tạp của việc phân nhánh và merge.

## Tại Sao Chọn Rebase? Lý Do Cho Lịch Sử Sạch Đẹp

Rebase tạo ra một lịch sử commit tuyến tính đẹp mắt, dễ đọc và dễ hiểu hơn. Khi bạn nhìn vào lịch sử dự án, nó kể một câu chuyện mạch lạc mà không có tiếng ồn từ vô số merge commits làm lộn xộn timeline.

Cách tiếp cận tuyến tính này giúp đơn giản hóa việc:

- Theo dõi tiến trình logic của các thay đổi
- Sử dụng các công cụ như `git bisect` để tìm bugs
- Review lịch sử dự án mà không bị lạc trong mạng lưới merge commits

## Quy Tắc Vàng: Không Bao Giờ Rebase Public Branches

Đây là điều nghiêm túc: **không bao giờ rebase các branch đã được push lên shared repository mà người khác đang làm việc**. Tại sao? Bởi vì rebase viết lại lịch sử bằng cách tạo các commits mới với SHA hashes khác nhau.

Nếu bạn rebase một public branch:

1. Các commits của bạn nhận SHA hashes mới
2. Local branches của developers khác vẫn trỏ đến các commits cũ
3. Hỗn loạn xảy ra khi họ cố gắng push hoặc pull
4. Hàng giờ (hoặc hàng ngày) frustration theo sau

**Merge an toàn hơn cho teams** chính xác vì nó không viết lại lịch sử. Nó chỉ đơn giản thêm commits mới lên trên các commits hiện có, vì vậy local repositories của mọi người đều giữ đồng bộ.

## Tận Dụng Ưu Điểm Của Cả Hai: Sử Dụng Rebase Chiến Lược

Điểm tối ưu? **Sử dụng rebase cho local feature branches của bạn trước khi tạo PR**.

Đây là một quy trình điển hình:

```bash
# Đang làm việc trên feature branch
git checkout feature-branch

# Trước khi submit PR, rebase lên main mới nhất
git fetch origin
git rebase origin/main

# Bây giờ các thay đổi của bạn nằm gọn gàng trên top của main
```

Điều này mang lại cho bạn lịch sử sạch hơn của rebase trong khi vẫn giữ các shared branches an toàn với merge.

## Interactive Rebase: Công Cụ Dọn Dẹp Commits

Một trong những siêu năng lực của rebase là **interactive rebase** (`git rebase -i`), cho phép bạn dọn dẹp commits trước khi share chúng:

```bash
git rebase -i HEAD~5
```

Lệnh này mở một editor nơi bạn có thể:

- **Reword** commit messages
- **Squash** nhiều commits thành một
- **Reorder** commits
- **Drop** commits hoàn toàn
- **Edit** nội dung commit

Nó hoàn hảo để biến các commits lộn xộn, work-in-progress của bạn thành một chuỗi thay đổi bóng bẩy và logic.

## Git Pull --rebase: Tiết Kiệm Thời Gian Hàng Ngày

Thay vì `git pull` (thực hiện fetch + merge), hãy sử dụng:

```bash
git pull --rebase
```

Lệnh này fetch các thay đổi từ remote và rebase các local commits của bạn lên trên chúng, tránh các merge commits không cần thiết cho các updates đơn giản. Nó giữ lịch sử local branch của bạn sạch hơn mà không gặp rủi ro của việc rebase public branches.

Bạn thậm chí có thể đặt nó làm mặc định:

```bash
git config --global pull.rebase true
```

## Ma Trận Quyết Định: Khi Nào Sử Dụng Cái Gì

| Tình Huống                                | Dùng Merge | Dùng Rebase        |
| ----------------------------------------- | ---------- | ------------------ |
| Tích hợp feature vào main                 | ✅         | ❌                 |
| Cập nhật feature branch với main mới nhất | ✅         | ✅ (nếu chưa push) |
| Dọn dẹp commits trước PR                  | ❌         | ✅                 |
| Làm việc trên public/shared branch        | ✅         | ❌                 |
| Pull các thay đổi mới nhất                | ✅         | ✅ (qua --rebase)  |
| Nhiều người trên cùng feature branch      | ✅         | ❌                 |

## Suy Nghĩ Cuối Cùng

Cả merge và rebase đều là những công cụ mạnh mẽ, và những Git users giỏi nhất biết khi nào sử dụng mỗi cái:

- **Merge** bảo toàn lịch sử và an toàn hơn cho collaboration
- **Rebase** tạo lịch sử sạch hơn nhưng đòi hỏi sự cẩn thận và kỷ luật

Chìa khóa là sử dụng rebase **locally và privately** để đánh bóng công việc của bạn, sau đó sử dụng merge để tích hợp những thay đổi đã được đánh bóng đó vào các shared branches. Theo cách tiếp cận này, và bạn sẽ duy trì được cả lịch sử commit sạch đẹp lẫn một team vui vẻ.

Hãy nhớ: với sức mạnh rebase to lớn đi kèm trách nhiệm to lớn. Khi còn nghi ngờ, hãy merge. Teammates của bạn sẽ cảm ơn bạn.

---

_Có câu hỏi về Git workflows? Hãy để lại trong comments bên dưới nhé!_
