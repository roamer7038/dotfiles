#!/bin/sh
# Claude Code statusLine command

input=$(cat)

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // empty')

# --- Directory (home -> ~, last 2 components) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
disp_cwd=$cwd
case "$cwd" in
  "$HOME") disp_cwd="~" ;;
  "$HOME"/*) disp_cwd="~/${cwd#"$HOME"/}" ;;
esac
short_cwd=$(echo "$disp_cwd" | awk -F'/' '{
  n=NF; if(n<=2) { print $0 } else {
    printf ".../%s/%s", $(n-1), $n
  }
}')

# --- Git branch (skip optional locks) ---
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.checkStat=minimal symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "$cwd" -c core.checkStat=minimal diff --quiet 2>/dev/null \
       && git -C "$cwd" -c core.checkStat=minimal diff --cached --quiet 2>/dev/null; then
      git_info="$branch"
    else
      git_info="${branch}*"
    fi
  fi
fi

# --- Context usage (progress bar) ---
ctx_str=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx_int=$(printf '%.0f' "$used_pct")
  bar=$(awk -v p="$ctx_int" 'BEGIN{
    w=10; f=int(p/100*w+0.5); if(f>w)f=w; if(f<0)f=0;
    s=""; for(i=0;i<f;i++)s=s"\xe2\x96\x88";
    for(i=f;i<w;i++)s=s"\xe2\x96\x91"; print s
  }')
  ctx_str="[${bar}] ${ctx_int}%"
fi

# --- Cost ---
cost_str=""
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$total_cost" ]; then
  cost_str="\$$(printf '%.4f' "$total_cost")"
fi

# --- Duration (human-readable) ---
time_str=""
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
if [ -n "$duration_ms" ]; then
  time_str=$(awk -v ms="$duration_ms" 'BEGIN{
    s=ms/1000;
    if(s<60){ printf "%.1fs", s }
    else if(s<3600){ m=int(s/60); sec=int(s%60); printf "%dm %ds", m, sec }
    else { h=int(s/3600); m=int((s%3600)/60); printf "%dh %dm", h, m }
  }')
fi

# --- Rate limits ---
rate_str=""
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five_h" ]; then
  rate_str="5h:$(printf '%.0f' "$five_h")%"
fi
if [ -n "$seven_d" ]; then
  if [ -n "$rate_str" ]; then
    rate_str="${rate_str} 7d:$(printf '%.0f' "$seven_d")%"
  else
    rate_str="7d:$(printf '%.0f' "$seven_d")%"
  fi
fi

# --- Rendering (all gray, labeled) ---
RESET="\033[0m"
GRAY="\033[38;5;245m"
SEP="\033[38;5;240m|\033[0m"

out=""
add() {
  [ -z "$2" ] && return
  [ -n "$out" ] && out="${out} ${SEP} "
  out="${out}${GRAY}$1${2}${RESET}"
}

add "Model: " "$model"
add "Dir: " "$short_cwd"
add "Branch: " "$git_info"
add "Ctx: " "$ctx_str"
add "Cost: " "$cost_str"
add "Time: " "$time_str"
add "Rate: " "$rate_str"

printf "%b" "$out"
