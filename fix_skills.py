import re

with open('/dados/aider/aider_core.sh', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix BASE_SKILLS
content = re.sub(r'("\$AIDER_GLOBAL_DIR/skills/.*\.md")', r'--read \1', content)

# Fix agent invocations to remove the explicit --read before ${SKILLS[@]} or ${BASE_SKILLS[@]}
content = content.replace('--read "${BASE_SKILLS[@]}"', '"${BASE_SKILLS[@]}"')
content = content.replace('--read "${SKILLS[@]}"', '"${SKILLS[@]}"')

with open('/dados/aider/aider_core.sh', 'w', encoding='utf-8') as f:
    f.write(content)

