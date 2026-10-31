# AI usage: dsc26-flt-w03

## 1. Tools I used

- Claude: to understand the task requirements, get implementation guidance, review code, and understand errors and testing results.

## 2. The prompts that helped most

1. "Understanding & Planning: Analyzing task requirements and organizing the project structure. "\
2. "Help me implement QuestionApi and PracticeRepository while following the exact task requirements, especially error handling and retry behavior."\
3. "Testing & Debuggin: Drafting additional tests and troubleshooting Dart analyzer warnings."

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

While reviewing the Cubit and repository interaction, I noticed a possible weakness related to H13 (leaving mid-request).

The Cubit checks (isClosed) after the repository request finishes, which prevents it from emitting a new state after being closed. However, if the Cubit is closed while the repository is waiting during a retry delay, the repository does not know that the screen has been removed and may continue with another API request.

I noticed this by tracing what happens when the screen is removed during a retry wait. This is a potential improvement rather than a confirmed failure in the public tests.

## 4. My state-management choice

I chose Bloc/Cubit because it separates the screen UI from the state-management logic and makes the loading, success, empty, and failure states easier to manage and test.
