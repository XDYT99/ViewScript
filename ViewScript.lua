local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI
local ScreenGui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- واجهة الكاميرا (المحقق)
local CamFrame = Instance.new("Frame")
CamFrame.Size = UDim2.new(0, 60, 0, 40)
CamFrame.Position = UDim2.new(0.85,0,0.05,0)
CamFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
CamFrame.BorderSizePixel = 0
CamFrame.Active = true
CamFrame.Parent = ScreenGui

local CamBtn = Instance.new("TextButton", CamFrame)
CamBtn.Size = UDim2.new(1,0,1,0)
CamBtn.Text = "🕵️"
CamBtn.TextScaled = true
CamBtn.BackgroundTransparency = 1

-- الأسهم في منتصف الشاشة (بعد تعديل التباعد على محور X)
local LeftArrow = Instance.new("TextButton", ScreenGui)
LeftArrow.Size = UDim2.new(0,40,0,40)
LeftArrow.Position = UDim2.new(0.25,0,0.85,0) -- بعدت على X
LeftArrow.Text = "<"
LeftArrow.Visible = false

local RightArrow = Instance.new("TextButton", ScreenGui)
RightArrow.Size = UDim2.new(0,40,0,40)
RightArrow.Position = UDim2.new(0.7,0,0.85,0) -- بعدت على X
RightArrow.Text = ">"
RightArrow.Visible = false

-- اسم اللاعب
local PlayerLabel = Instance.new("TextLabel", ScreenGui)
PlayerLabel.Size = UDim2.new(0.2,0,0,40)
PlayerLabel.Position = UDim2.new(0.4,0,0.8,-40)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.TextColor3 = Color3.fromRGB(255,255,255)
PlayerLabel.TextScaled = true
PlayerLabel.Text = ""
PlayerLabel.Visible = false

-- متغيرات المراقبة
local Viewing = false
local targetIndex = 1
local targets = {}

local function updateTargets()
    targets = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= plr and p.Character and p.Character:FindFirstChild("Humanoid") then
            table.insert(targets,p)
        end
    end
    if targetIndex > #targets then targetIndex = 1 end
end

local function updateLabel()
    if #targets == 0 then
        PlayerLabel.Text = ""
    else
        local target = targets[targetIndex]
        PlayerLabel.Text = "("..(target.Name or "Player")..")"
    end
end

local function startView()
    Viewing = true
    updateTargets()
    if #targets > 0 then
        Camera.CameraSubject = targets[targetIndex].Character.Humanoid
        LeftArrow.Visible = true
        RightArrow.Visible = true
        PlayerLabel.Visible = true
        updateLabel()
    end
end

local function stopView()
    Viewing = false
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = plr.Character.Humanoid
    end
    LeftArrow.Visible = false
    RightArrow.Visible = false
    PlayerLabel.Visible = false
end

local function changeTarget(delta)
    if #targets == 0 then return end
    targetIndex = targetIndex + delta
    if targetIndex < 1 then targetIndex = #targets end
    if targetIndex > #targets then targetIndex = 1 end
    Camera.CameraSubject = targets[targetIndex].Character and targets[targetIndex].Character:FindFirstChild("Humanoid")
    updateLabel()
end

-- زر الكاميرا
CamBtn.MouseButton1Click:Connect(function()
    if Viewing then
        stopView()
    else
        startView()
    end
end)

-- الأسهم
LeftArrow.MouseButton1Click:Connect(function()
    changeTarget(-1)
end)

RightArrow.MouseButton1Click:Connect(function()
    changeTarget(1)
end)

-- تحديث اللاعبين الجدد تلقائياً
Players.PlayerAdded:Connect(function()
    if Viewing then
        updateTargets()
        updateLabel()
    end
end)

-- تحريك الكاميرا باللمس
local lastPos = nil
local pinchDistance = nil

UserInputService.InputChanged:Connect(function(input, gpe)
    if not Viewing then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        if input.UserInputState == Enum.UserInputState.Moved then
            local touches = UserInputService:GetTouches()
            if #touches == 1 then
                local delta = touches[1].Position - (lastPos or touches[1].Position)
                lastPos = touches[1].Position
                Camera.CFrame = Camera.CFrame * CFrame.Angles(0, -delta.X/200, 0) * CFrame.Angles(-delta.Y/200,0,0)
            elseif #touches == 2 then
                local dist = (touches[1].Position - touches[2].Position).magnitude
                if pinchDistance then
                    local diff = dist - pinchDistance
                    Camera.CFrame = Camera.CFrame * CFrame.new(0,0,-diff/10)
                end
                pinchDistance = dist
            end
        end
        lastPos = input.Position
    end
end)

UserInputService.TouchEnded:Connect(function(input)
    if #UserInputService:GetTouches() < 2 then
        pinchDistance = nil
    end
    if #UserInputService:GetTouches() == 0 then
        lastPos = nil
    end
end)

-- جعل المحقق 🕵️ قابل للسحب
local dragging = false
local dragStartPos
local frameStartPos

CamBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = input.Position
        frameStartPos = CamFrame.Position
    end
end)

CamBtn.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStartPos
        CamFrame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

CamBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- عداد الضغطات المخفي لإخفاء السكربت وإعادة الكاميرا
local count = 10
local lastClick = tick()
CamBtn.MouseButton1Click:Connect(function()
    local now = tick()
    if now - lastClick > 3 then
        count = 10
    end
    count = count - 1
    lastClick = now
    if count <= 0 then
        -- إعادة الكاميرا لللاعب قبل التدمير
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = plr.Character.Humanoid
        end
        ScreenGui:Destroy()
    end
end)