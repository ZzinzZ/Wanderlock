import os,sys
out=sys.argv[1]
INK="#2B2140"
B={
"palace":'''<rect x="8" y="26" width="48" height="22" rx="3" fill="#FFF3D1"/><rect x="5" y="21" width="54" height="7" rx="2" fill="#F2D9A2"/><path d="M16 29V47M24 29V47M40 29V47M48 29V47" fill="none"/><rect x="27" y="36" width="10" height="12" rx="1" fill="#8FD3F0"/><path d="M32 21V7" fill="none"/><path d="M32 8H45L42 12L45 16H32Z" fill="#FF6B5B"/>''',
"post":'''<path d="M6 25L32 11L58 25Z" fill="#F29E4C"/><rect x="8" y="25" width="48" height="23" rx="2" fill="#F7C95E"/><circle cx="32" cy="19" r="4" fill="#FFFFFF"/><path d="M24 48V38A8 8 0 0 1 40 38V48Z" fill="#8FD3F0"/><rect x="12" y="31" width="7" height="9" rx="1" fill="#8FD3F0"/><rect x="45" y="31" width="7" height="9" rx="1" fill="#8FD3F0"/>''',
"market":'''<rect x="5" y="31" width="54" height="17" rx="3" fill="#F4A06A"/><rect x="24" y="13" width="16" height="35" rx="2" fill="#FFD9A8"/><path d="M21 13L32 4L43 13Z" fill="#E8604C"/><circle cx="32" cy="22" r="5" fill="#FFFFFF"/><path d="M32 22V19M32 22H35" fill="none"/><path d="M28 48V41A4 4 0 0 1 36 41V48Z" fill="#8FD3F0"/><rect x="10" y="36" width="8" height="6" rx="1" fill="#FFF3D1"/><rect x="46" y="36" width="8" height="6" rx="1" fill="#FFF3D1"/>''',
"museum":'''<rect x="8" y="22" width="48" height="26" rx="3" fill="#B8C6EC"/><rect x="5" y="16" width="54" height="7" rx="2" fill="#8FA3DC"/><rect x="13" y="28" width="8" height="8" rx="1" fill="#FFFFFF"/><rect x="28" y="28" width="8" height="8" rx="1" fill="#FFFFFF"/><rect x="43" y="28" width="8" height="8" rx="1" fill="#FFFFFF"/><rect x="27" y="39" width="10" height="9" rx="1" fill="#FFC93C"/>''',
"pagoda":'''<rect x="14" y="38" width="36" height="10" rx="2" fill="#FFD27A"/><path d="M5 39Q32 29 59 39L52 32Q32 25 12 32Z" fill="#E8604C"/><rect x="21" y="23" width="22" height="10" rx="2" fill="#FFD27A"/><path d="M12 25Q32 15 52 25L46 19Q32 12 18 19Z" fill="#E8604C"/><circle cx="32" cy="11" r="3.5" fill="#FFC93C"/><rect x="28" y="40" width="8" height="8" rx="1" fill="#8B4A2B"/>''',
"temple":'''<rect x="10" y="30" width="44" height="18" rx="2" fill="#FF8A7A"/><path d="M4 31Q32 19 60 31L54 24Q32 14 10 24Z" fill="#2FA36B"/><path d="M8 22Q6 17 11 18M56 22Q58 17 53 18" fill="none"/><rect x="27" y="36" width="10" height="12" rx="1" fill="#FFC93C"/><circle cx="18" cy="36" r="3.5" fill="#E8304C"/><circle cx="46" cy="36" r="3.5" fill="#E8304C"/>''',
"wharf":'''<rect x="10" y="28" width="44" height="18" rx="2" fill="#FFF3D1"/><path d="M6 28L32 15L58 28Z" fill="#E8604C"/><path d="M8 20Q12 14 17 19M56 20Q52 14 47 19" fill="none"/><rect x="16" y="33" width="7" height="8" rx="1" fill="#8FD3F0"/><rect x="41" y="33" width="7" height="8" rx="1" fill="#8FD3F0"/><rect x="28" y="34" width="8" height="12" rx="1" fill="#8FD3F0"/><path d="M6 52Q11 49 16 52T26 52T36 52T46 52T58 52" fill="none" stroke="#2F9BEA"/>''',
"tower":'''<rect x="18" y="34" width="28" height="14" rx="2" fill="#7CC7EE"/><rect x="22" y="21" width="20" height="14" rx="2" fill="#9FD8F5"/><rect x="26" y="9" width="12" height="13" rx="2" fill="#C6ECFB"/><path d="M32 9V3" fill="none"/><path d="M26 28H38M22 41H42" fill="none"/>''',
}
GROUND='<ellipse cx="32" cy="50" rx="27" ry="6" fill="#8BDB7A"/>'
for k,v in B.items():
    body=GROUND+v
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><g stroke="#FFFFFF" stroke-width="8" stroke-linejoin="round" stroke-linecap="round" fill="#FFFFFF">{body.replace('fill="none"','').replace('stroke="#2F9BEA"','')}</g><g stroke="{INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'''
    open(os.path.join(out,k+'.svg'),'w',encoding='utf-8').write(svg)
print(os.listdir(out))
