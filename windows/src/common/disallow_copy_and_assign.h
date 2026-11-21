#ifndef WINDOW_FRAME_SRC_COMMON_DISALLOW_COPY_AND_ASSIGN_H_
#define WINDOW_FRAME_SRC_COMMON_DISALLOW_COPY_AND_ASSIGN_H_

// Classes that hold references to their collaborators must not be copied.
#define WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(TypeName) \
  TypeName(const TypeName&) = delete;                    \
  TypeName& operator=(const TypeName&) = delete

#endif  // WINDOW_FRAME_SRC_COMMON_DISALLOW_COPY_AND_ASSIGN_H_
