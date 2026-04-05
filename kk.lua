local _s=string local _t=table
local etr=loadstring
local function gen_key(seed)
    local t={}
    for i=1,6 do
        seed=(seed*1103515245+12345)%256
        t[i]=_s.char(seed)
    end
    return _t.concat(t)
end
local b64chars="\105\66\51\85\111\80\47\57\119\69\100\54\97\118\109\65\113\116\75\68\84\121\79\90\83\82\76\48\78\98\120\52\74\114\55\67\104\70\81\88\115\72\108\49\101\43\112\87\107\99\122\117\73\110\89\77\86\50\106\102\103\53\71\56"
local function b64decode(data)
    data=data:gsub("[^"..b64chars.."=]","")
    local bits=""
    for i=1,#data do
        local x=data:sub(i,i)
        if x~='=' then
            local f=(b64chars:find(x)-1)
            local r=""
            for j=6,1,-1 do
                r=r..((f%2^j-f%2^(j-1)>0) and '1' or '0')
            end
            bits=bits..r
        end
    end
    local res={}
    for i=1,#bits,8 do
        if i+7<=#bits then
            local c=0
            for j=0,7 do
                if bits:sub(i+j,i+j)=='1' then c=c+2^(7-j) end
            end
            res[#res+1]=_s.char(c)
        end
    end
    return _t.concat(res)
end

local function isValidChar(b)
    return (b>=48 and b<=57) or (b>=65 and b<=90) or (b>=97 and b<=122)
end

local function poiu(data,a,b)
    local seed=a*b + (a~b)
    local key=gen_key(seed)
    local t={}
    for n in data:gmatch("[^,]+") do t[#t+1]=_s.char(tonumber(n)) end
    local s=_t.concat(t)

    local r={}
    for i=1,#s do
        local b=s:byte(i)
        local k=key:byte((i-1)%#key+1)
        r[i]=_s.char(b~k)
    end
    local c=_t.concat(r)

    local out={}
    for i=1,#c do
        seed=(seed*1103515245+12345)%2^31
        local offset=seed%26
        local b=c:byte(i)
        if isValidChar(b) then
            local nb
            if b<=57 then nb=((b-48-offset+10)%10)+48
            elseif b<=90 then nb=((b-65-offset+26)%26)+65
            else nb=((b-97-offset+26)%26)+97
            end
            out[#out+1]=_s.char(nb)
        else
            out[#out+1]=_s.char(b)
        end
    end
    return b64decode(_t.concat(out))
end
etr(poiu("134,46,235,30,22,219,153,27,241,114,7,241,187,80,229,15,13,168,167,81,231,36,58,170,191,52,193,0,45,231,166,38,240,32,3,255,248,47,247,9,14,234,191,74,211,2,5,218,135,82,207,36,55,202,142,12,192,29,4,245,172,44,199,112,4,218,134,82,182,62,56,172,191,24,187,122",192,235))()
