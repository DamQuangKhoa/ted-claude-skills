# Git Rebase vs Merge: Lựa Chọn Đúng Cho Workflow Của Bạn

> **Dành cho developers muốn hiểu sâu về git history và collaboration best practices**

Bạn đã bao giờ nhìn vào git history của project và thấy nó trông như một mớ hỗn độn với vô số merge commits không? Hoặc ngược lại, bạn từng vô tình rebase một branch đã được push lên remote và làm toàn team loạn lên? Việc chọn giữa `git merge` và `git rebase` là một trong những quyết định quan trọng nhất ảnh hưởng đến code collaboration.

Trong bài viết này, chúng ta sẽ đi sâu vào cách hoạt động của merge và rebase, khi nào nên dùng cái nào, và những best practices để tránh gặp rắc rối.

## Phần 1: Hiểu Về Git Merge

### 1.1 Merge Hoạt Động Như Thế Nào?

Git merge tạo ra một **merge commit** mới để kết hợp hai branches lại với nhau. Merge commit này có hai parent commits - một từ branch hiện tại và một từ branch được merge vào.

```bash
# Merge feature branch vào main
git checkout main
git merge feature-branch
```

**Kết quả trong git history:**

```
      A---B---C feature-branch
     /         \
D---E---F---G---M main
```

Commit `M` là merge commit, nó kết nối history của cả hai branches.

### 1.2 Ưu Điểm Của Merge

**Bảo toàn toàn bộ lịch sử:**

- Mọi commit đều được giữ nguyên
- Context đầy đủ về khi nào và như thế nào các thay đổi được tích hợp
- Dễ dàng truy vết lại quá trình phát triển

**An toàn cho team collaboration:**

- Không thay đổi existing commits
- Không conflict với những gì đã được push lên remote
- Transparent - mọi người đều thấy được merge points

```bash
# Safe workflow cho team
git checkout main
git pull origin main
git checkout feature-branch
git merge main          # Sync với latest main
git push origin feature-branch
```

### 1.3 Nhược Điểm Của Merge

**History có thể trở nên rối:**

```
*   Merge branch 'feature-1' into main
|\
| * Fix typo
| * Add tests
| * Implement feature
* | Merge branch 'feature-2' into main
|\|
| * Another fix
| * Some work
* | Merge branch 'hotfix' into main
```

Với nhiều features được develop song song, git history có thể trở nên khó đọc và khó hiểu luồng phát triển chính.

## Phần 2: Hiểu Về Git Rebase

### 2.1 Rebase Hoạt Động Như Thế Nào?

Git rebase **viết lại history** bằng cách áp dụng lại các commits của bạn lên trên một base commit mới. Thay vì tạo merge commit, rebase di chuyển toàn bộ feature branch của bạn đến tip của target branch.

```bash
# Rebase feature branch lên main
git checkout feature-branch
git rebase main
```

**Trước khi rebase:**

```
      A---B---C feature-branch
     /
D---E---F---G main
```

**Sau khi rebase:**

```
              A'---B'---C' feature-branch
             /
D---E---F---G main
```

Lưu ý: `A'`, `B'`, `C'` là các commits **mới** với SHA khác, mặc dù nội dung giống với `A`, `B`, `C`.

### 2.2 Ưu Điểm Của Rebase

**Linear history - sạch đẹp và dễ đọc:**

```bash
# Linear history after rebase
D---E---F---G---A---B---C
```

Không có merge commits, mọi thứ theo một đường thẳng. Khi đọc git log, bạn thấy chính xác trình tự các thay đổi được implement.

**Git log rất clean:**

```bash
$ git log --oneline
c3d2a1f (HEAD -> feature-branch) Add comprehensive tests
b8e9f0c Implement user authentication
a7d6c5b Update dependencies
f9e8d7c Merge pull request #42
```

So với log có nhiều merge commits, linear history giúp easier để understand project evolution.

### 2.3 Interactive Rebase - Công Cụ Mạnh Mẽ

Một trong những tính năng mạnh nhất của rebase là **interactive mode**:

```bash
git rebase -i HEAD~3
```

Điều này mở một editor cho phép bạn:

```
pick a7d6c5b Implement feature
pick b8e9f0c Fix bug
pick c3d2a1f Add tests

# Commands:
# p, pick = use commit
# r, reword = use commit, but edit message
# e, edit = use commit, but stop for amending
# s, squash = meld into previous commit
# f, fixup = like squash, but discard message
# d, drop = remove commit
```

**Use cases phổ biến:**

**1. Squash commits trước khi PR:**

```bash
# Thay vì:
- WIP: initial work
- Fix typo
- Fix another typo
- Actually fix the thing
- Add tests

# Thành:
- Implement user authentication with tests
```

**2. Reorder commits logic:**

```bash
# Sắp xếp lại commits theo logic:
- Add database migration
- Update models
- Add API endpoints
- Add tests
```

**3. Clean up commit messages:**

```bash
# From: "fixed stuff" "ugh why" "this works now"
# To: "Refactor authentication flow"
     "Add comprehensive error handling"
     "Improve test coverage"
```

## Phần 3: Khi Nào Dùng Merge, Khi Nào Dùng Rebase?

### 3.1 The Golden Rule of Rebase

> **KHÔNG BAO GIỜ REBASE PUBLIC BRANCHES**

Đây là rule quan trọng nhất. Nếu branch của bạn đã được push lên remote và người khác có thể đang work trên đó, **đừng rebase**.

**Tại sao?** Vì rebase tạo ra new commits với new SHAs. Nếu ai đó đã pull branch cũ, history của họ sẽ conflict với rebased version:

```
Your teammate's local:     Your rebased version:
A---B---C                  A'---B'---C'

# Git sẽ thấy đây như diverged branches!
```

Kết quả: conflicts, confusion, và có thể mất code.

### 3.2 Merge - An Toàn Cho Shared Branches

**Dùng MERGE khi:**

✅ Integrating shared branches (main ← feature)
✅ Branch đã được publish/pushed ra remote
✅ Làm việc trong một team (multiple people on same branch)
✅ Cần preserve đầy đủ context và history
✅ Uncertainty về ai đang work trên branch

**Workflow điển hình:**

```bash
# Feature development complete
git checkout main
git pull origin main
git merge feature-branch
git push origin main
```

### 3.3 Rebase - Tốt Cho Local Feature Branches

**Dùng REBASE khi:**

✅ Cleaning up local commits trước khi PR
✅ Branch của bạn chưa được share với ai
✅ Muốn linear history
✅ Sync feature branch với latest main
✅ Feature branch development (before pushing)

**Workflow điển hình:**

```bash
# Keep feature branch updated with main
git checkout feature-branch
git fetch origin
git rebase origin/main

# Clean up commits before PR
git rebase -i HEAD~5

# Now push (first time or with --force-with-lease)
git push origin feature-branch --force-with-lease
```

### 3.4 Git Pull Rebase - Best Practice

Khi pull changes từ remote, bạn có hai options:

```bash
# Default: merge (creates merge commit)
git pull origin main

# Rebase: linear history
git pull --rebase origin main
# Hoặc
git config pull.rebase true  # Set as default
```

**Git pull --rebase workflow:**

```
# Before pull:
      Your local work
      D---E (local main)
     /
A---B---C (remote main)

# After git pull --rebase:
A---B---C---D'---E' (main)
```

Điều này giữ history linear và tránh unnecessary merge commits từ việc sync với remote.

## Phần 4: Best Practices và Common Pitfalls

### 4.1 Feature Branch Workflow

**Recommended approach:**

```bash
# 1. Start feature branch from main
git checkout -b feature/user-auth main

# 2. Make commits as you work
git commit -m "Add login endpoint"
git commit -m "Add password hashing"
git commit -m "Add tests"

# 3. Periodically sync with main (rebase while still private)
git fetch origin
git rebase origin/main

# 4. Clean up commits before PR
git rebase -i HEAD~3  # Squash/reorganize

# 5. Push to remote
git push origin feature/user-auth

# 6. Create PR - từ đây dùng MERGE
# After PR approved:
git checkout main
git pull origin main  # Should include your merged PR
```

### 4.2 Safety với --force-with-lease

Nếu bạn đã rebase một branch đã được push, bạn cần force push. **Never use `--force`**, luôn dùng `--force-with-lease`:

```bash
# ❌ DANGEROUS
git push --force

# ✅ SAFER
git push --force-with-lease origin feature-branch
```

`--force-with-lease` chỉ force push nếu remote branch hasn't been updated since you last fetched. Điều này protect against accidentally overwriting work từ teammates.

### 4.3 Recovery From Rebase Mistakes

Nếu rebase goes wrong, **đừng panic**:

```bash
# Git giữ reference log của mọi operations
git reflog

# Output:
# c3d2a1f HEAD@{0}: rebase finished
# a7d6c5b HEAD@{1}: rebase: Add tests
# f9e8d7c HEAD@{2}: checkout: moving from main to feature

# Reset về state trước rebase
git reset --hard HEAD@{2}
```

Git reflog là safety net của bạn - nó tracks tất cả changes đến HEAD, cho phép bạn undo almost anything.

### 4.4 So Sánh Nhanh

| Tiêu chí         | Merge                            | Rebase                                |
| :--------------- | :------------------------------- | :------------------------------------ |
| **History**      | Preserves all commits và context | Linear, cleaner history               |
| **Safety**       | Very safe, no history rewriting  | Requires caution with public branches |
| **Team work**    | Ideal cho collaboration          | Good for solo feature work            |
| **Traceability** | Full context với merge points    | Context có thể bị lost                |
| **Complexity**   | Simpler, straightforward         | More powerful, requires understanding |
| **Use case**     | Integrating shared branches      | Cleaning up local work                |

## Phần 5: Khi Nào Cả Hai Đều OK?

Trong practice, bạn thường **combine both approaches**:

```bash
# Typical workflow combining both:

# 1. Local feature development - sử dụng rebase tự do
git rebase -i HEAD~3  # Clean up commits
git rebase main       # Stay updated with main

# 2. Before creating PR
git push origin feature-branch

# 3. Team review và updates trên PR
# Other developers có thể add commits
git pull origin feature-branch  # Now dùng merge!

# 4. Final integration vào main
# Via PR merge (GitHub/GitLab handles this)
# Most teams dùng "Squash and merge" hoặc "Rebase and merge"
```

## Key Takeaways

✅ **Merge creates merge commits** - safe, preserves history, tốt cho team collaboration

✅ **Rebase rewrites history** - creates linear history, cleaner log, tốt cho feature branches

❌ **Never rebase public/shared branches** - sẽ cause conflicts và confusion

✅ **Rebase local feature branches** trước khi push or create PR - clean commit history

✅ **Interactive rebase (`-i`)** là tool mạnh mẽ để clean up commits, reorder, squash

✅ **Use `git pull --rebase`** để avoid unnecessary merge commits

✅ **`--force-with-lease`** safer than `--force` khi cần force push

✅ **Merge for integration**, **rebase for refinement**

## Kết Luận

Choosing giữa merge và rebase không phải là either/or decision - đó là about understanding **when to use each approach**. Merge provides safety và full context, perfect cho team collaboration và shared branches. Rebase gives you clean, linear history và powerful tools để refine your work, ideal cho local feature development.

**Workflow recommendation:**

- Rebase freely trên local feature branches
- Clean up commits với interactive rebase trước PR
- Sync với main using rebase while branch still private
- Switch to merge once branch is shared/pushed
- Use merge for final integration vào main branch

Bằng cách follow these practices, bạn sẽ maintain clean git history without compromising team collaboration hay risking lost work.

---

**Next Steps:**

- Practice interactive rebase trên a test repository
- Set up `git config pull.rebase true` for cleaner pulls
- Establish team conventions về when to merge vs rebase
- Learn about `git reflog` for recovery options
