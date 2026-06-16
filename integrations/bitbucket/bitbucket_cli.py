import os
import sys
import subprocess
import urllib.request
import urllib.error
import json
import base64
import re

def get_git_remote():
    try:
        output = subprocess.check_output(["git", "remote", "-v"], text=True).strip()
        for line in output.split('\n'):
            if 'origin' in line and ('fetch' in line or 'push' in line):
                # Extrai git@bitbucket.org:workspace/repo.git ou https://user@bitbucket.org/workspace/repo.git
                match = re.search(r'bitbucket\.org[:/]([^/]+)/([^/.\s]+)(?:\.git)?', line)
                if match:
                    return match.group(1), match.group(2)
        return None, None
    except Exception:
        return None, None

def fetch_pr_comments(pr_id):
    username = os.environ.get("BITBUCKET_USERNAME")
    app_password = os.environ.get("BITBUCKET_APP_PASSWORD")
    
    if not username or not app_password:
        print("⚠️ ERRO: Credenciais do Bitbucket não encontradas.")
        print("Configure as variáveis BITBUCKET_USERNAME e BITBUCKET_APP_PASSWORD no seu ambiente (ex: aider_env.sh).")
        sys.exit(1)
        
    workspace, repo_slug = get_git_remote()
    
    # Fallback para variáveis de ambiente caso o git remote não identifique o Bitbucket
    workspace = os.environ.get("BITBUCKET_WORKSPACE", workspace)
    repo_slug = os.environ.get("BITBUCKET_REPO", repo_slug)
    
    if not workspace or not repo_slug:
        print("⚠️ ERRO: Não foi possível inferir o workspace e repositório pelo git remote.")
        print("Por favor, declare BITBUCKET_WORKSPACE e BITBUCKET_REPO no seu ambiente.")
        sys.exit(1)
        
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/pullrequests/{pr_id}/comments"
    
    auth_str = f"{username}:{app_password}"
    b64_auth = base64.b64encode(auth_str.encode("utf-8")).decode("utf-8")
    
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Basic {b64_auth}")
    req.add_header("Accept", "application/json")
    
    try:
        response = urllib.request.urlopen(req)
        data = json.loads(response.read().decode("utf-8"))
        
        comments = data.get("values", [])
        if not comments:
            print(f"✅ Nenhum comentário encontrado no PR #{pr_id}.")
            return
            
        print(f"### Comentários Ativos do PR #{pr_id} (Repositório: {workspace}/{repo_slug})\n")
        
        for comment in comments:
            if comment.get("deleted"):
                continue
                
            content = comment.get("content", {}).get("raw", "")
            author = comment.get("user", {}).get("display_name", "Desconhecido")
            inline = comment.get("inline", {})
            
            file_path = inline.get("path")
            line_no = inline.get("to") or inline.get("from")
            
            # Formatação especial para a IA entender o contexto e a exata linha do código
            if file_path:
                print(f"📍 Arquivo: `{file_path}` (Linha: {line_no})")
            else:
                print(f"💬 Comentário Geral no PR:")
                
            print(f"👤 {author} apontou:")
            print(f"   {content}")
            print("-" * 60)
            
    except urllib.error.HTTPError as e:
        print(f"⚠️ Erro ao acessar a API do Bitbucket: {e.code} - {e.reason}")
        if e.code == 401:
            print("Status 401: Falha na autenticação. Verifique se o seu App Password possui a permissão de leitura de 'Pull requests'.")
        sys.exit(1)
    except Exception as e:
        print(f"⚠️ Ocorreu um erro na requisição: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] != "pr":
        print("Uso interno pelo Aider: python bitbucket_cli.py pr <id_do_pr>")
        sys.exit(1)
        
    pr_id = sys.argv[2]
    fetch_pr_comments(pr_id)
