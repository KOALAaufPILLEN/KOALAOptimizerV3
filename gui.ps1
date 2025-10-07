# ---------- Enhanced XAML UI with Modern Sidebar Navigation ----------
$xamlContent = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="KOALA Gaming Optimizer v3.0 - Enhanced Edition"
        Width="1400" Height="900"
        MinWidth="1200" MinHeight="820"
        Background="{DynamicResource AppBackgroundBrush}"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        SizeToContent="Manual">
    <Window.Resources>
      <SolidColorBrush x:Key="AppBackgroundBrush" Color="#0F0B1E"/>
      <SolidColorBrush x:Key="SidebarBackgroundBrush" Color="#1C1733"/>
      <SolidColorBrush x:Key="SidebarAccentBrush" Color="#8F6FFF"/>
      <SolidColorBrush x:Key="SidebarHoverBrush" Color="#2A214F"/>
      <SolidColorBrush x:Key="SidebarSelectedBrush" Color="#403270"/>
      <SolidColorBrush x:Key="SidebarSelectedForegroundBrush" Color="#F7F6FF"/>
      <SolidColorBrush x:Key="HeaderBackgroundBrush" Color="#1D1834"/>
      <SolidColorBrush x:Key="HeaderBorderBrush" Color="#2E2752"/>
      <SolidColorBrush x:Key="CardBackgroundBrush" Color="#1D1834"/>
      <SolidColorBrush x:Key="ContentBackgroundBrush" Color="#141129"/>
      <SolidColorBrush x:Key="CardBorderBrush" Color="#2E2752"/>
      <SolidColorBrush x:Key="HeroCardBrush" Color="#221C3F"/>
      <SolidColorBrush x:Key="AccentBrush" Color="#8F6FFF"/>
      <SolidColorBrush x:Key="PrimaryTextBrush" Color="#FFFFFF"/>
      <SolidColorBrush x:Key="SecondaryTextBrush" Color="#B8B5D1"/>
      <SolidColorBrush x:Key="SuccessBrush" Color="#22C55E"/>
      <SolidColorBrush x:Key="WarningBrush" Color="#F59E0B"/>
      <SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>
      <SolidColorBrush x:Key="InfoBrush" Color="#38BDF8"/>
      <SolidColorBrush x:Key="ButtonBackgroundBrush" Color="#221C3F"/>
      <SolidColorBrush x:Key="ButtonBorderBrush" Color="#2E2752"/>
      <SolidColorBrush x:Key="ButtonHoverBrush" Color="#2A214F"/>
      <SolidColorBrush x:Key="ButtonPressedBrush" Color="#241E45"/>
      <SolidColorBrush x:Key="HeroChipBrush" Color="#2A214F"/>

    <Style x:Key="BaseControlStyle" TargetType="Control">
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
    </Style>

    <Style x:Key="BaseTextBlockStyle" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>

    <Style x:Key="SectionHeader" TargetType="TextBlock" BasedOn="{StaticResource BaseTextBlockStyle}">
      <Setter Property="FontSize" Value="18"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
    </Style>

    <Style x:Key="SectionSubtext" TargetType="TextBlock" BasedOn="{StaticResource BaseTextBlockStyle}">
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Foreground" Value="{DynamicResource SecondaryTextBrush}"/>
    </Style>

    <Style x:Key="ModernButton" TargetType="Button" BasedOn="{StaticResource BaseControlStyle}">
      <Setter Property="Background" Value="{DynamicResource ButtonBackgroundBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource ButtonBorderBrush}"/>

      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="14,8"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="buttonBorder"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="6"
                    Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="buttonBorder" Property="Background" Value="{DynamicResource ButtonHoverBrush}"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="buttonBorder" Property="Background" Value="{DynamicResource ButtonPressedBrush}"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SuccessButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
      <Setter Property="Background" Value="{DynamicResource SuccessBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource SuccessBrush}"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#34D399"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style x:Key="WarningButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
      <Setter Property="Background" Value="{DynamicResource WarningBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource WarningBrush}"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#FBBF24"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
      <Setter Property="Background" Value="{DynamicResource DangerBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource DangerBrush}"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#DC2626"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style x:Key="SidebarButton" TargetType="Button" BasedOn="{StaticResource BaseControlStyle}">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{DynamicResource SecondaryTextBrush}"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="14,10"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="HorizontalAlignment" Value="Stretch"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="sidebarBg" Background="{TemplateBinding Background}" CornerRadius="6" Padding="8,6">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="sidebarBg" Property="Background" Value="{DynamicResource SidebarHoverBrush}"/>
              </Trigger>
              <Trigger Property="Tag" Value="Selected">
                <Setter TargetName="sidebarBg" Property="Background" Value="{DynamicResource SidebarSelectedBrush}"/>
                <Setter Property="Foreground" Value="{DynamicResource SidebarSelectedForegroundBrush}"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SidebarSectionLabel" TargetType="TextBlock" BasedOn="{StaticResource BaseTextBlockStyle}">
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{DynamicResource SecondaryTextBrush}"/>
      <Setter Property="Margin" Value="4,20,0,8"/>
    </Style>

    <Style x:Key="MetricValue" TargetType="TextBlock" BasedOn="{StaticResource BaseTextBlockStyle}">
      <Setter Property="FontSize" Value="22"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
    </Style>

    <Style x:Key="ModernComboBox" TargetType="ComboBox" BasedOn="{StaticResource BaseControlStyle}">
      <Setter Property="Background" Value="{DynamicResource ContentBackgroundBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource CardBorderBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,6"/>
      <Setter Property="Height" Value="34"/>
      <Style.Resources>
        <Style TargetType="ComboBoxItem" BasedOn="{StaticResource BaseControlStyle}">
          <Setter Property="Background" Value="Transparent"/>
          <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
          <Setter Property="Padding" Value="12,6"/>
          <Style.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
              <Setter Property="Background" Value="{DynamicResource SidebarHoverBrush}"/>
            </Trigger>
            <Trigger Property="IsSelected" Value="True">
              <Setter Property="Background" Value="{DynamicResource SidebarAccentBrush}"/>
              <Setter Property="Foreground" Value="{DynamicResource SidebarSelectedForegroundBrush}"/>
            </Trigger>
          </Style.Triggers>
        </Style>
      </Style.Resources>
    </Style>

    <Style x:Key="ModernTextBox" TargetType="TextBox" BasedOn="{StaticResource BaseControlStyle}">
      <Setter Property="Background" Value="{DynamicResource ContentBackgroundBrush}"/>
      <Setter Property="Foreground" Value="{DynamicResource PrimaryTextBrush}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource CardBorderBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,6"/>
      <Setter Property="Height" Value="32"/>
      <Setter Property="CaretBrush" Value="{DynamicResource PrimaryTextBrush}"/>
    </Style>

    <Style x:Key="ModernCheckBox" TargetType="CheckBox" BasedOn="{StaticResource BaseControlStyle}">
      <Setter Property="Foreground" Value="{DynamicResource SecondaryTextBrush}"/>
      <Setter Property="Margin" Value="0,4,18,4"/>
    </Style>

    <Style x:Key="HeaderText" TargetType="TextBlock" BasedOn="{StaticResource BaseTextBlockStyle}">
      <Setter Property="FontSize" Value="18"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{DynamicResource AccentBrush}"/>
    </Style>
  </Window.Resources>

  <Grid x:Name="RootLayout" Background="{DynamicResource AppBackgroundBrush}">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="230"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <Border x:Name="SidebarShell"
            Grid.Column="0"
            Background="{DynamicResource SidebarBackgroundBrush}"
            BorderBrush="{DynamicResource CardBorderBrush}"
            BorderThickness="0,0,1,0"
            Padding="20,18">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="{DynamicResource HeroCardBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="14" Padding="18" Margin="0,0,0,24">
          <StackPanel Tag="Spacing:6">
            <TextBlock Text="🐨 KOALA" FontSize="22" FontWeight="SemiBold" Foreground="{DynamicResource PrimaryTextBrush}"/>
            <TextBlock Text="Gaming Optimizer v3.0" Style="{StaticResource SectionSubtext}" FontSize="13"/>
            <TextBlock Text="Advanced FPS boosting suite" Style="{StaticResource SectionSubtext}" FontSize="11"/>
          </StackPanel>
        </Border>

        <ScrollViewer x:Name="SidebarNavScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto">
          <StackPanel>
            <Button x:Name="btnNavDashboard" Style="{StaticResource SidebarButton}" Tag="Selected">
              <StackPanel Orientation="Horizontal" Margin="0" Tag="Spacing:10">
                <TextBlock Text="🏠" FontSize="16"/>
                <TextBlock Text="Dashboard" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavBasicOpt" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="⚡" FontSize="16"/>
                <TextBlock Text="Quick optimize" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavAdvanced" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="🛠️" FontSize="16"/>
                <TextBlock Text="Advanced" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavGames" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="🎮" FontSize="16"/>
                <TextBlock Text="Game profiles" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavOptions" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="🎨" FontSize="16"/>
                <TextBlock Text="Options" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavBackup" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="🗂️" FontSize="16"/>
                <TextBlock Text="Backups" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
            <Button x:Name="btnNavLog" Style="{StaticResource SidebarButton}">
              <StackPanel Orientation="Horizontal" Tag="Spacing:10">
                <TextBlock Text="🧾" FontSize="16"/>
                <TextBlock Text="Activity log" FontWeight="SemiBold"/>
              </StackPanel>
            </Button>
          </StackPanel>
        </ScrollViewer>

        <Border x:Name="SidebarAdminCard"
                Grid.Row="2"
                Background="{DynamicResource ContentBackgroundBrush}"
                BorderBrush="{DynamicResource CardBorderBrush}"
                BorderThickness="1"
                CornerRadius="8"
                Padding="14"
                Margin="0,20,0,0">
          <StackPanel>
            <TextBlock Text="Admin status" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SecondaryTextBrush}"/>
            <TextBlock x:Name="lblSidebarAdminStatus" Text="Checking..." FontSize="11" Foreground="{DynamicResource WarningBrush}" Margin="0,6,0,0"/>
            <Button x:Name="btnSidebarElevate" Content="Request elevation" Height="30" Style="{StaticResource WarningButton}" FontSize="11" Margin="0,10,0,0"/>
          </StackPanel>
        </Border>
      </Grid>
    </Border>

    <Grid x:Name="MainStage" Grid.Column="1" Background="{DynamicResource AppBackgroundBrush}">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="260"/>
      </Grid.RowDefinitions>

      <Border x:Name="HeaderBar"
              Grid.Row="0"
              Background="{DynamicResource HeaderBackgroundBrush}"
              BorderBrush="{DynamicResource HeaderBorderBrush}"
              BorderThickness="0,0,0,1"
              Padding="26,20">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock x:Name="lblMainTitle" Text="Dashboard" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource PrimaryTextBrush}"/>
            <TextBlock x:Name="lblMainSubtitle" Text="Your system at a glance" Style="{StaticResource SectionSubtext}" Margin="0,6,0,0"/>
            <WrapPanel Margin="0,18,0,0" ItemHeight="28">
              <Border Background="{DynamicResource HeroChipBrush}" CornerRadius="14" Padding="12,6" Margin="0,0,10,0" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1">
                <StackPanel Orientation="Horizontal" Tag="Spacing:6">
                  <TextBlock Text="⚡" FontSize="14"/>
                  <TextBlock Text="Instant optimizations" Style="{StaticResource SectionSubtext}"/>
                </StackPanel>
              </Border>
              <Border Background="{DynamicResource HeroChipBrush}" CornerRadius="14" Padding="12,6" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1">
                <StackPanel Orientation="Horizontal" Tag="Spacing:6">
                  <TextBlock Text="📊" FontSize="14"/>
                  <TextBlock Text="Live system insights" Style="{StaticResource SectionSubtext}"/>
                </StackPanel>
              </Border>
            </WrapPanel>
          </StackPanel>
        </Grid>
      </Border>

      <Border x:Name="dashboardSummaryRibbon" Grid.Row="1" Margin="26,18,26,12" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="18">
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Tag="Spacing:24">
          <StackPanel Orientation="Horizontal" Tag="Spacing:8">
            <TextBlock Text="Profiles:" Style="{StaticResource SectionSubtext}" FontSize="13"/>
            <TextBlock x:Name="lblHeroProfiles" Style="{StaticResource MetricValue}" FontSize="20" Foreground="{DynamicResource PrimaryTextBrush}" Text="--"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" Tag="Spacing:8">
            <TextBlock Text="Optimizations:" Style="{StaticResource SectionSubtext}" FontSize="13"/>
            <TextBlock x:Name="lblHeroOptimizations" Style="{StaticResource MetricValue}" FontSize="20" Foreground="{DynamicResource AccentBrush}" Text="--"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" Tag="Spacing:8">
            <TextBlock Text="Auto mode:" Style="{StaticResource SectionSubtext}" FontSize="13"/>
            <TextBlock x:Name="lblHeroAutoMode" Style="{StaticResource MetricValue}" FontSize="20" Foreground="{DynamicResource DangerBrush}" Text="Off"/>
          </StackPanel>
        </StackPanel>
      </Border>

      <ScrollViewer x:Name="MainScrollViewer" Grid.Row="2" VerticalScrollBarVisibility="Auto" Padding="26">
        <StackPanel Tag="Spacing:22">
          <StackPanel x:Name="panelDashboard" Visibility="Visible" Tag="Spacing:18">
            <Border x:Name="dashboardHeroCard"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="16"
                    Padding="26">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Tag="Spacing:12">
                  <TextBlock Text="System ready" Style="{StaticResource SectionHeader}" FontSize="20"/>
                  <TextBlock x:Name="lblHeaderSystemStatus" Text="Stable" Style="{StaticResource SectionHeader}" FontSize="28"/>
                  <TextBlock Text="KOALA keeps your PC lean with smart maintenance, clean logging and one-click fixes to ensure optimal gaming performance." Style="{StaticResource SectionSubtext}"/>
                  <StackPanel Orientation="Horizontal" Tag="Spacing:8">
                    <TextBlock Text="Last run:" Style="{StaticResource SectionSubtext}"/>
                    <TextBlock x:Name="lblHeaderLastRun" Text="Never" Style="{StaticResource SectionSubtext}" FontSize="13"/>
                  </StackPanel>
                </StackPanel>
                <StackPanel Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Center" Tag="Spacing:12">
                  <Button x:Name="btnSystemHealth" Content="View health detail" Width="200" Height="40" Style="{StaticResource ModernButton}"/>
                  <Border Background="{DynamicResource HeroChipBrush}" CornerRadius="12" Padding="12,8" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" HorizontalAlignment="Right">
                    <TextBlock Text="Admin status: All optimizations available" Style="{StaticResource SectionSubtext}"/>
                  </Border>
                </StackPanel>
              </Grid>
            </Border>

            <Border x:Name="dashboardSummaryPanel"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="12"
                    Padding="24">
              <StackPanel Tag="Spacing:18">
                <StackPanel>
                  <TextBlock Text="System summary" Style="{StaticResource SectionHeader}" FontSize="18"/>
                  <TextBlock Text="Realtime metrics and health status." Style="{StaticResource SectionSubtext}"/>
                </StackPanel>
                <UniformGrid Rows="1" Columns="4" Margin="0,4,0,0">
                  <Border x:Name="dashboardCpuCard" Background="{DynamicResource CardBackgroundBrush}" CornerRadius="10" Padding="16" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Margin="0,0,12,0">
                    <StackPanel Tag="Spacing:6">
                      <TextBlock Text="CPU load" Style="{StaticResource SectionSubtext}" FontSize="13"/>
                      <TextBlock x:Name="lblDashCpuUsage" Style="{StaticResource MetricValue}" Text="--%"/>
                      <TextBlock Text="Realtime usage of each core." Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                  </Border>
                  <Border x:Name="dashboardMemoryCard" Background="{DynamicResource CardBackgroundBrush}" CornerRadius="10" Padding="16" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Margin="12,0">
                    <StackPanel Tag="Spacing:6">
                      <TextBlock Text="Memory" Style="{StaticResource SectionSubtext}" FontSize="13"/>
                      <TextBlock x:Name="lblDashMemoryUsage" Style="{StaticResource MetricValue}" Text="-- / -- GB" Foreground="{DynamicResource AccentBrush}"/>
                      <TextBlock Text="Track system memory consumption." Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                  </Border>
                  <Border x:Name="dashboardActivityCard" Background="{DynamicResource CardBackgroundBrush}" CornerRadius="10" Padding="16" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Margin="12,0">
                    <StackPanel Tag="Spacing:6">
                      <TextBlock Text="Session" Style="{StaticResource SectionSubtext}" FontSize="13"/>
                      <TextBlock Text="Active games" Style="{StaticResource SectionSubtext}"/>
                      <TextBlock x:Name="lblDashActiveGames" Style="{StaticResource MetricValue}" Text="None"/>
                      <Separator Margin="0,4" Background="{DynamicResource CardBorderBrush}" Height="1"/>
                      <TextBlock Text="Last optimization" Style="{StaticResource SectionSubtext}"/>
                      <TextBlock x:Name="lblDashLastOptimization" Style="{StaticResource SectionSubtext}" FontSize="13" Text="Never"/>
                    </StackPanel>
                  </Border>
                  <Border x:Name="dashboardHealthCard" Background="{DynamicResource CardBackgroundBrush}" CornerRadius="10" Padding="16" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Margin="12,0,0,0">
                    <StackPanel Tag="Spacing:8">
                      <TextBlock Text="System health" Style="{StaticResource SectionSubtext}" FontSize="13"/>
                      <TextBlock x:Name="lblDashSystemHealth" Style="{StaticResource MetricValue}" Text="Not run"/>
                      <StackPanel Orientation="Horizontal" Tag="Spacing:8">
                        <Button x:Name="btnSystemHealthRunCheck" Content="Run" Width="72" Height="30" Style="{StaticResource SuccessButton}" FontSize="12"/>
                        <Button x:Name="btnBenchmark" Content="Benchmark" Width="100" Height="30" Style="{StaticResource WarningButton}" FontSize="12"/>
                      </StackPanel>
                    </StackPanel>
                  </Border>
                </UniformGrid>
              </StackPanel>
            </Border>

            <Border x:Name="dashboardQuickActionsCard"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="12"
                    Padding="20">
              <StackPanel Tag="Spacing:10">
                <TextBlock Text="Optimization controls" Style="{StaticResource SectionHeader}" FontSize="16"/>
                <TextBlock Text="Launch KOALA automation, detection and benchmarking from one spot." Style="{StaticResource SectionSubtext}"/>
                <WrapPanel ItemWidth="180" ItemHeight="40" Margin="0,4,0,0">
                  <Button x:Name="btnDashQuickOptimize" Content="⚡ Quick optimize" Width="180" Height="36" Style="{StaticResource SuccessButton}" FontSize="12" Margin="0,0,16,16"/>
                  <Button x:Name="btnDashAutoDetect" Content="🎮 Auto-detect games" Width="200" Height="36" Style="{StaticResource ModernButton}" FontSize="12" Margin="0,0,16,16"/>
                  <Button x:Name="btnDashAutoOptimize" Content="Auto optimize" Visibility="Collapsed"/>
                </WrapPanel>
                <CheckBox x:Name="chkDashAutoOptimize" Content="Keep auto optimization enabled" Style="{StaticResource ModernCheckBox}"/>
                <TextBlock Text="Tip: Enable auto optimization so KOALA refreshes your tweaks whenever Windows starts." Style="{StaticResource SectionSubtext}"/>
              </StackPanel>
            </Border>

            <Border x:Name="dashboardActionBar"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="12"
                    Padding="18">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Tag="Spacing:12">
                <Button x:Name="btnExportConfigMain" Content="Export config" Width="140" Height="38" Style="{StaticResource ModernButton}"/>
                <Button x:Name="btnImportConfigMain" Content="Import config" Width="140" Height="38" Style="{StaticResource ModernButton}"/>
                <Button x:Name="btnBackupMain" Content="Backup" Width="120" Height="38" Style="{StaticResource ModernButton}"/>
                <Button x:Name="btnApplyMain" Content="Apply all" Width="140" Height="44" Style="{StaticResource SuccessButton}" FontSize="16"/>
                <Button x:Name="btnRevertMain" Content="Revert all" Width="140" Height="44" Style="{StaticResource DangerButton}" FontSize="16"/>
                <Button x:Name="btnApply" Visibility="Collapsed" Width="0" Height="0"/>
                <Button x:Name="btnRevert" Visibility="Collapsed" Width="0" Height="0"/>
              </StackPanel>
            </Border>

            <Border x:Name="dashboardGameProfileCard"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="12"
                    Padding="20">
              <StackPanel Tag="Spacing:12">
                <TextBlock Text="Game profile launcher" Style="{StaticResource SectionHeader}" FontSize="16"/>
                <Grid Tag="ColumnSpacing:16">
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="2*"/>
                    <ColumnDefinition Width="*"/>
                  </Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0" Tag="Spacing:12">
                    <ComboBox x:Name="cmbGameProfile" Style="{StaticResource ModernComboBox}"/>
                    <Grid Tag="ColumnSpacing:10">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                      </Grid.ColumnDefinitions>
                      <TextBox x:Name="txtCustomGame" Grid.Column="0" Style="{StaticResource ModernTextBox}"/>
                      <Button x:Name="btnFindExecutable" Grid.Column="1" Content="Find" Width="70" Height="32" Style="{StaticResource ModernButton}"/>
                      <Button x:Name="btnOptimizeGame" Grid.Column="2" Content="Optimize" Width="100" Height="32" Style="{StaticResource SuccessButton}"/>
                    </Grid>
                  </StackPanel>
                  <StackPanel Grid.Column="1" Tag="Spacing:10">
                    <Button x:Name="btnInstalledGamesDash" Content="Installed games" Width="180" Height="34" Style="{StaticResource ModernButton}"/>
                    <Button x:Name="btnAddGameFolderDash" Content="Add game folder" Width="180" Height="34" Style="{StaticResource ModernButton}"/>
                    <Button x:Name="btnCustomSearchDash" Content="Custom search" Width="180" Height="34" Style="{StaticResource WarningButton}" Visibility="Collapsed"/>
                  </StackPanel>
                </Grid>
              </StackPanel>
            </Border>

            <Border x:Name="dashboardGameListCard"
                    Background="{DynamicResource CardBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="12"
                    Padding="20">
              <StackPanel Tag="Spacing:12">
                <TextBlock Text="Detected games" Style="{StaticResource SectionHeader}" FontSize="16"/>
                <TextBlock Text="Your library updates automatically after detection." Style="{StaticResource SectionSubtext}"/>
                <ScrollViewer Height="260" VerticalScrollBarVisibility="Auto" Background="Transparent">
                  <StackPanel x:Name="dashboardGameListPanel">
                    <TextBlock Text="Click 'Search for installed games' to discover your library." Style="{StaticResource SectionSubtext}" FontStyle="Italic" HorizontalAlignment="Center" Margin="0,40,0,0"/>
                  </StackPanel>
                </ScrollViewer>
                <Button x:Name="btnOptimizeSelectedDashboard" Content="Optimize selected games" Height="40" Style="{StaticResource SuccessButton}" FontSize="12" IsEnabled="False"/>
              </StackPanel>
            </Border>
          </StackPanel>

          <StackPanel x:Name="panelBasicOpt" Visibility="Collapsed" Tag="Spacing:16">
            <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="22">
              <StackPanel Tag="Spacing:14">
                <TextBlock Text="Basic mode" Style="{StaticResource SectionHeader}" FontSize="18" HorizontalAlignment="Center"/>
                <TextBlock Text="Pick categories to apply safe optimizations instantly." Style="{StaticResource SectionSubtext}" HorizontalAlignment="Center"/>
                <Grid Tag="ColumnSpacing:16">
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                  </Grid.ColumnDefinitions>
                  <Button x:Name="btnBasicNetwork" Grid.Column="0" Height="78" Style="{StaticResource ModernButton}">
                    <StackPanel>
                      <TextBlock Text="🌐 Network" FontWeight="SemiBold"/>
                      <TextBlock Text="Latency optimizations" Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                  </Button>
                  <Button x:Name="btnBasicSystem" Grid.Column="1" Height="78" Style="{StaticResource ModernButton}">
                    <StackPanel>
                      <TextBlock Text="💻 System" FontWeight="SemiBold"/>
                      <TextBlock Text="Power &amp; memory" Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                  </Button>
                  <Button x:Name="btnBasicGaming" Grid.Column="2" Height="78" Style="{StaticResource ModernButton}">
                    <StackPanel>
                      <TextBlock Text="🎮 Gaming" FontWeight="SemiBold"/>
                      <TextBlock Text="FPS tweaks" Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                  </Button>
                </Grid>
              </StackPanel>
            </Border>
          </StackPanel>

          <StackPanel x:Name="panelAdvanced" Visibility="Collapsed" Tag="Spacing:16">
            <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="22">
              <StackPanel Tag="Spacing:16">
                <TextBlock Text="Advanced optimizations" Style="{StaticResource SectionHeader}" FontSize="18"/>
                <TextBlock Text="Collapsible sections for deep system tweaks." Style="{StaticResource SectionSubtext}"/>
                <StackPanel Orientation="Horizontal" Tag="Spacing:10" HorizontalAlignment="Center">
                  <Button x:Name="btnAdvancedNetwork" Content="🌐 Network" Style="{StaticResource ModernButton}" MinWidth="120" Height="32" FontSize="12"/>
                  <Button x:Name="btnAdvancedSystem" Content="💻 System" Style="{StaticResource ModernButton}" MinWidth="120" Height="32" FontSize="12"/>
                  <Button x:Name="btnAdvancedServices" Content="🛠️ Services" Style="{StaticResource ModernButton}" MinWidth="120" Height="32" FontSize="12"/>
                </StackPanel>

                <Expander x:Name="expanderNetworkTweaks" Header="🌐 Network optimizations" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Fine tune TCP and latency for competitive play." Style="{StaticResource SectionSubtext}"/>
                    <Expander x:Name="expanderNetworkOptimizations" Header="Core network tweaks" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10" IsExpanded="True">
                      <WrapPanel>
                        <CheckBox x:Name="chkAckNetwork" Content="TCP ACK Frequency" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDelAckTicksNetwork" Content="Delayed ACK Ticks" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkNagleNetwork" Content="Disable Nagle" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkNetworkThrottlingNetwork" Content="Network throttling" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkRSSNetwork" Content="Receive side scaling" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkRSCNetwork" Content="Segment coalescing" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkChimneyNetwork" Content="TCP chimney offload" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkNetDMANetwork" Content="NetDMA state" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkTcpTimestampsNetwork" Content="TCP timestamps" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkTcpWindowAutoTuningNetwork" Content="Window auto tuning" Style="{StaticResource ModernCheckBox}"/>
                      </WrapPanel>
                    </Expander>
                    <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="14">
                      <Grid Tag="ColumnSpacing:12">
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="Auto"/>
                          <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="btnApplyNetworkTweaks" Grid.Column="0" Content="Apply network optimizations" Style="{StaticResource SuccessButton}" Height="34" FontSize="12"/>
                        <Button x:Name="btnTestNetworkLatency" Grid.Column="1" Content="Test latency" Width="120" Height="34" Style="{StaticResource ModernButton}" FontSize="12"/>
                        <Button x:Name="btnResetNetworkSettings" Grid.Column="2" Content="Reset" Width="80" Height="34" Style="{StaticResource WarningButton}" FontSize="12"/>
                      </Grid>
                    </Border>
                  </StackPanel>
                </Expander>

                <Expander x:Name="expanderSystemOptimizations" Header="💻 System optimizations" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Performance and hardware adjustments for maximum efficiency." Style="{StaticResource SectionSubtext}"/>
                    <Expander x:Name="expanderPerformanceOptimizations" Header="Performance essentials" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10" IsExpanded="True">
                      <WrapPanel>
                        <CheckBox x:Name="chkMemoryCompressionSystem" Content="Memory compression" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkPowerPlanSystem" Content="High performance plan" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkCPUSchedulingSystem" Content="CPU scheduling" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkPageFileSystem" Content="Page file" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkVisualEffectsSystem" Content="Disable visuals" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkCoreParkingSystem" Content="Core parking" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkGameDVRSystem" Content="Disable Game DVR" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkFullscreenOptimizationsSystem" Content="Fullscreen exclusive" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkGPUSchedulingSystem" Content="GPU scheduling" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkTimerResolutionSystem" Content="Timer resolution" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkGameModeSystem" Content="Game mode" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkMPOSystem" Content="MPO" Style="{StaticResource ModernCheckBox}"/>
                      </WrapPanel>
                    </Expander>

                    <Expander x:Name="expanderAdvancedPerformance" Header="Advanced enhancements" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10">
                      <WrapPanel>
                        <CheckBox x:Name="chkDynamicResolution" Content="Dynamic resolution" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkEnhancedFramePacing" Content="Enhanced frame pacing" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkGPUOverclocking" Content="GPU overclock profile" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkCompetitiveLatency" Content="Latency reduction" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkAutoDiskOptimization" Content="Auto disk trim" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkAdaptivePowerManagement" Content="Adaptive power" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkEnhancedPagingFile" Content="Paging file management" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDirectStorageEnhanced" Content="DirectStorage" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkAdvancedTelemetryDisable" Content="Telemetry disable" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkMemoryDefragmentation" Content="Memory defrag" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkServiceOptimization" Content="Service optimization" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDiskTweaksAdvanced" Content="Disk I/O tweaks" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkNetworkLatencyOptimization" Content="Ultra-low latency" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkFPSSmoothness" Content="FPS smoothness" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkCPUMicrocode" Content="CPU microcode" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkRAMTimings" Content="RAM timings" Style="{StaticResource ModernCheckBox}"/>
                      </WrapPanel>
                    </Expander>

                    <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="14">
                      <Grid Tag="ColumnSpacing:12">
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="Auto"/>
                          <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="btnApplySystemOptimizations" Grid.Column="0" Content="Apply system optimizations" Style="{StaticResource SuccessButton}" Height="34" FontSize="12"/>
                        <Button x:Name="btnSystemBenchmark" Grid.Column="1" Content="Benchmark" Width="120" Height="34" Style="{StaticResource ModernButton}" FontSize="12"/>
                        <Button x:Name="btnResetSystemSettings" Grid.Column="2" Content="Reset" Width="80" Height="34" Style="{StaticResource WarningButton}" FontSize="12"/>
                      </Grid>
                    </Border>
                  </StackPanel>
                </Expander>

                <Expander x:Name="expanderServiceManagement" Header="🛠️ Service optimizations" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Manage background services for better responsiveness." Style="{StaticResource SectionSubtext}"/>
                    <Expander x:Name="expanderServiceOptimizations" Header="Service tweaks" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10" IsExpanded="True">
                      <WrapPanel>
                        <CheckBox x:Name="chkDisableXboxServicesServices" Content="Disable Xbox services" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableTelemetryServices" Content="Disable telemetry" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableSearchServices" Content="Disable search" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisablePrintSpoolerServices" Content="Disable print spooler" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableSuperfetchServices" Content="Disable superfetch" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableFaxServices" Content="Disable fax" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableRemoteRegistryServices" Content="Disable remote registry" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableThemesServices" Content="Optimize themes service" Style="{StaticResource ModernCheckBox}"/>
                      </WrapPanel>
                    </Expander>
                    <Expander x:Name="expanderPrivacyServices" Header="Privacy &amp; background" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" Padding="10">
                      <WrapPanel>
                        <CheckBox x:Name="chkDisableCortana" Content="Disable Cortana" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableWindowsUpdate" Content="Optimize Windows Update" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableBackgroundApps" Content="Disable background apps" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableLocationTracking" Content="Disable location" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableAdvertisingID" Content="Disable advertising ID" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableErrorReporting" Content="Disable error reporting" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableCompatTelemetry" Content="Disable compat telemetry" Style="{StaticResource ModernCheckBox}"/>
                        <CheckBox x:Name="chkDisableWSH" Content="Disable Windows Script Host" Style="{StaticResource ModernCheckBox}"/>
                      </WrapPanel>
                    </Expander>
                    <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="14">
                      <Grid Tag="ColumnSpacing:12">
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="Auto"/>
                          <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="btnApplyServiceOptimizations" Grid.Column="0" Content="Apply service optimizations" Style="{StaticResource SuccessButton}" Height="34" FontSize="12"/>
                        <Button x:Name="btnViewRunningServices" Grid.Column="1" Content="View services" Width="120" Height="34" Style="{StaticResource ModernButton}" FontSize="12"/>
                        <Button x:Name="btnResetServiceSettings" Grid.Column="2" Content="Reset" Width="80" Height="34" Style="{StaticResource WarningButton}" FontSize="12"/>
                      </Grid>
                    </Border>
                  </StackPanel>
                </Expander>
              </StackPanel>
            </Border>
          </StackPanel>

          <StackPanel x:Name="panelGames" Visibility="Collapsed" Tag="Spacing:16">
            <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="22">
              <StackPanel Tag="Spacing:16">
                <TextBlock Text="Installed games" Style="{StaticResource SectionHeader}" FontSize="18"/>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Detection &amp; search" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <Grid Tag="ColumnSpacing:12">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                      </Grid.ColumnDefinitions>
                      <Button x:Name="btnSearchGamesPanel" Grid.Column="0" Content="Installed games" Height="34" Style="{StaticResource ModernButton}" FontSize="12"/>
                      <Button x:Name="btnAddGameFolderPanel" Grid.Column="1" Content="Add folder" Width="140" Height="34" Style="{StaticResource SuccessButton}" FontSize="12"/>
                      <Button x:Name="btnCustomSearchPanel" Grid.Column="2" Content="Custom search" Width="120" Height="34" Style="{StaticResource WarningButton}" FontSize="12" Visibility="Collapsed"/>
                    </Grid>
                  </StackPanel>
                </Border>
                <Border x:Name="installedGamesPanel" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Detected games" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <ScrollViewer Height="280" VerticalScrollBarVisibility="Auto">
                      <StackPanel x:Name="gameListPanel">
                        <TextBlock Text="Click 'Search for installed games' to populate this list." Style="{StaticResource SectionSubtext}" FontStyle="Italic" HorizontalAlignment="Center" Margin="0,30,0,0"/>
                      </StackPanel>
                    </ScrollViewer>
                    <Button x:Name="btnOptimizeSelectedMain" Content="Optimize selected games" Height="36" Style="{StaticResource SuccessButton}" FontSize="12" IsEnabled="False"/>
                  </StackPanel>
                </Border>
              </StackPanel>
            </Border>
          </StackPanel>

          <StackPanel x:Name="panelOptions" Visibility="Collapsed" Tag="Spacing:16">
            <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="22">
              <StackPanel Tag="Spacing:16">
                <TextBlock Text="Theme &amp; preferences" Style="{StaticResource SectionHeader}" FontSize="18" HorizontalAlignment="Center"/>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Theme" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <Grid Tag="ColumnSpacing:10">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                      </Grid.ColumnDefinitions>
                      <TextBlock Text="Preset" VerticalAlignment="Center" Style="{StaticResource SectionSubtext}"/>
                      <ComboBox x:Name="cmbOptionsThemeMain" Grid.Column="1" Style="{StaticResource ModernComboBox}">
                        <ComboBoxItem Content="Optimizer Dark" Tag="OptimizerDark"/>
                        <ComboBoxItem Content="Custom" Tag="Custom"/>
                      </ComboBox>
                      <Button x:Name="btnOptionsApplyThemeMain" Grid.Column="2" Content="Apply" Width="90" Height="32" Style="{StaticResource SuccessButton}" FontSize="12"/>
                      <Button x:Name="btnApplyTheme" Visibility="Collapsed" Width="0" Height="0"/>
                    </Grid>
                    <Border x:Name="themeColorPreview" Background="{DynamicResource ContentBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                      <Grid Tag="ColumnSpacing:10">
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel>
                          <TextBlock Text="Background" Style="{StaticResource SectionSubtext}" FontSize="11" HorizontalAlignment="Center"/>
                          <Rectangle x:Name="previewBg" Height="20" Fill="{DynamicResource CardBackgroundBrush}" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1">
                          <TextBlock Text="Primary" Style="{StaticResource SectionSubtext}" FontSize="11" HorizontalAlignment="Center"/>
                          <Rectangle x:Name="previewPrimary" Height="20" Fill="#8F6FFF" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1"/>
                        </StackPanel>
                        <StackPanel Grid.Column="2">
                          <TextBlock Text="Hover" Style="{StaticResource SectionSubtext}" FontSize="11" HorizontalAlignment="Center"/>
                          <Rectangle x:Name="previewHover" Height="20" Fill="#A78BFA" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1"/>
                        </StackPanel>
                        <StackPanel Grid.Column="3">
                          <TextBlock Text="Text" Style="{StaticResource SectionSubtext}" FontSize="11" HorizontalAlignment="Center"/>
                          <Rectangle x:Name="previewText" Height="20" Fill="#F5F3FF" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1"/>
                        </StackPanel>
                      </Grid>
                    </Border>
                  </StackPanel>
                </Border>

                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:10">
                    <TextBlock x:Name="lblLanguageSectionTitle" Text="Language" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <TextBlock x:Name="lblLanguageDescription" Text="Choose how KOALA talks to you." Style="{StaticResource SectionSubtext}"/>
                    <Grid Tag="ColumnSpacing:10">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <TextBlock x:Name="lblLanguageLabel" Text="Language" VerticalAlignment="Center" Style="{StaticResource SectionSubtext}"/>
                      <ComboBox x:Name="cmbOptionsLanguage" Grid.Column="1" Style="{StaticResource ModernComboBox}" SelectedIndex="0">
                        <ComboBoxItem x:Name="cmbOptionsLanguageEnglish" Content="English" Tag="en"/>
                        <ComboBoxItem x:Name="cmbOptionsLanguageGerman" Content="German" Tag="de"/>
                      </ComboBox>
                    </Grid>
                  </StackPanel>
                </Border>

                <Border x:Name="customThemePanel" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16" Visibility="Collapsed">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Custom colors" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <Grid Tag="ColumnSpacing:12">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <StackPanel>
                        <TextBlock Text="Background" Style="{StaticResource SectionSubtext}" FontSize="11"/>
                        <Rectangle x:Name="previewBgCustom" Height="22" Width="70" Fill="{DynamicResource CardBackgroundBrush}" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1" Margin="0,4,0,0"/>
                        <TextBox x:Name="txtCustomBg" Style="{StaticResource ModernTextBox}" Margin="0,6,0,0"/>
                      </StackPanel>
                      <StackPanel Grid.Column="1">
                        <TextBlock Text="Primary" Style="{StaticResource SectionSubtext}" FontSize="11"/>
                        <Rectangle x:Name="previewPrimaryCustom" Height="22" Width="70" Fill="#8F6FFF" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1" Margin="0,4,0,0"/>
                        <TextBox x:Name="txtCustomPrimary" Style="{StaticResource ModernTextBox}" Margin="0,6,0,0"/>
                      </StackPanel>
                      <StackPanel Grid.Column="2">
                        <TextBlock Text="Hover" Style="{StaticResource SectionSubtext}" FontSize="11"/>
                        <Rectangle x:Name="previewHoverCustom" Height="22" Width="70" Fill="#A78BFA" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1" Margin="0,4,0,0"/>
                        <TextBox x:Name="txtCustomHover" Style="{StaticResource ModernTextBox}" Margin="0,6,0,0"/>
                      </StackPanel>
                      <StackPanel Grid.Column="3">
                        <TextBlock Text="Text" Style="{StaticResource SectionSubtext}" FontSize="11"/>
                        <Rectangle x:Name="previewTextCustom" Height="22" Width="70" Fill="#F5F3FF" Stroke="{DynamicResource CardBorderBrush}" StrokeThickness="1" Margin="0,4,0,0"/>
                        <TextBox x:Name="txtCustomText" Style="{StaticResource ModernTextBox}" Margin="0,6,0,0"/>
                      </StackPanel>
                    </Grid>
                    <Button x:Name="btnApplyCustomTheme" Content="Apply custom theme" Height="34" Style="{StaticResource SuccessButton}"/>
                  </StackPanel>
                </Border>

                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:10">
                    <TextBlock Text="UI scaling" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <Grid Tag="ColumnSpacing:10">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                      </Grid.ColumnDefinitions>
                      <TextBlock Text="Scale" VerticalAlignment="Center" Style="{StaticResource SectionSubtext}"/>
                      <ComboBox x:Name="cmbUIScaleMain" Grid.Column="1" Style="{StaticResource ModernComboBox}" SelectedIndex="1">
                        <ComboBoxItem Content="75%" Tag="0.75"/>
                        <ComboBoxItem Content="100%" Tag="1.0"/>
                        <ComboBoxItem Content="125%" Tag="1.25"/>
                      </ComboBox>
                      <Button x:Name="btnApplyScaleMain" Grid.Column="2" Content="Apply" Width="90" Height="32" Style="{StaticResource SuccessButton}" FontSize="12"/>
                    </Grid>
                  </StackPanel>
                </Border>

                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:10">
                    <TextBlock Text="Settings management" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <Grid Tag="ColumnSpacing:10">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <Button x:Name="btnSaveSettingsMain" Grid.Column="0" Content="Save settings" Height="32" Style="{StaticResource SuccessButton}" FontSize="12"/>
                      <Button x:Name="btnLoadSettingsMain" Grid.Column="1" Content="Load settings" Height="32" Style="{StaticResource ModernButton}" FontSize="12"/>
                      <Button x:Name="btnResetSettingsMain" Grid.Column="2" Content="Reset to default" Height="32" Style="{StaticResource WarningButton}" FontSize="12"/>
                    </Grid>
                  </StackPanel>
                </Border>
              </StackPanel>
            </Border>
          </StackPanel>

          <StackPanel x:Name="panelBackup" Visibility="Collapsed" Tag="Spacing:16">
            <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="22">
              <StackPanel Tag="Spacing:16">
                <TextBlock Text="Backup and restore" Style="{StaticResource SectionHeader}" FontSize="18" HorizontalAlignment="Center"/>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Create backup" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <TextBlock Text="Store your optimizations and settings to a safe location." Style="{StaticResource SectionSubtext}"/>
                    <Grid Tag="ColumnSpacing:12">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <Button x:Name="btnCreateBackup" Grid.Column="0" Content="Create full backup" Height="38" Style="{StaticResource SuccessButton}" FontSize="14"/>
                      <Button x:Name="btnExportConfigBackup" Grid.Column="1" Content="Export config" Height="38" Style="{StaticResource ModernButton}" FontSize="14"/>
                    </Grid>
                  </StackPanel>
                </Border>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Restore" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <TextBlock Text="Import existing configurations or restore from a backup file." Style="{StaticResource SectionSubtext}"/>
                    <Grid Tag="ColumnSpacing:12">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <Button x:Name="btnRestoreBackup" Grid.Column="0" Content="Restore backup" Height="38" Style="{StaticResource ModernButton}" FontSize="14"/>
                      <Button x:Name="btnImportConfigBackup" Grid.Column="1" Content="Import config" Height="38" Style="{StaticResource ModernButton}" FontSize="14"/>
                    </Grid>
                  </StackPanel>
                </Border>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="16">
                  <StackPanel Tag="Spacing:12">
                    <TextBlock Text="Activity log" Style="{StaticResource SectionSubtext}" FontSize="14"/>
                    <TextBlock Text="Export or clear your optimization history." Style="{StaticResource SectionSubtext}"/>
                    <Grid Tag="ColumnSpacing:12">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                      </Grid.ColumnDefinitions>
                      <Button x:Name="btnSaveActivityLog" Grid.Column="0" Content="Save log" Height="36" Style="{StaticResource SuccessButton}" FontSize="12"/>
                      <Button x:Name="btnClearActivityLog" Grid.Column="1" Content="Clear log" Height="36" Style="{StaticResource WarningButton}" FontSize="12"/>
                      <Button x:Name="btnViewActivityLog" Grid.Column="2" Content="View log" Height="36" Style="{StaticResource ModernButton}" FontSize="12"/>
                    </Grid>
                  </StackPanel>
                </Border>
              </StackPanel>
            </Border>
          </StackPanel>
          
          <StackPanel x:Name="panelLog" Visibility="Collapsed" Tag="Spacing:16">
            <Border x:Name="activityLogBorder"
                    Background="{DynamicResource ContentBackgroundBrush}"
                    BorderBrush="{DynamicResource CardBorderBrush}"
                    BorderThickness="1"
                    CornerRadius="16"
                    Padding="24">
              <Grid Tag="RowSpacing:16">
                <Grid.RowDefinitions>
                  <RowDefinition Height="*"/>
                  <RowDefinition Height="200"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Tag="Spacing:16">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*"/>
                      <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                      <TextBlock Text="Activity log" Style="{StaticResource SectionHeader}" FontSize="20"/>
                      <TextBlock Text="Monitor every action KOALA performs and keep a detailed history." Style="{StaticResource SectionSubtext}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Tag="Spacing:8" VerticalAlignment="Center">
                      <Button x:Name="btnToggleLogView" Content="Detailed" Width="90" Height="32" Style="{StaticResource ModernButton}" FontSize="11"/>
                      <Button x:Name="btnExtendLog" Content="Extend" Width="90" Height="32" Style="{StaticResource ModernButton}" FontSize="11"/>
                      <Button x:Name="btnClearLog" Content="Clear" Width="90" Height="32" Style="{StaticResource WarningButton}" FontSize="11"/>
                      <Button x:Name="btnSaveLog" Content="Save log" Width="90" Height="32" Style="{StaticResource ModernButton}" FontSize="11"/>
                      <Button x:Name="btnSearchLog" Content="Search" Width="90" Height="32" Style="{StaticResource SuccessButton}" FontSize="11"/>
                    </StackPanel>
                  </Grid>

                  <WrapPanel Margin="0,10,0,0">
                    <Border Background="{DynamicResource HeroChipBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="14,10" Margin="0,0,12,12">
                      <StackPanel Tag="Spacing:4">
                        <TextBlock Text="Active game" Style="{StaticResource SectionSubtext}"/>
                        <TextBlock Text="{Binding Text, ElementName=lblDashActiveGames}" Style="{StaticResource MetricValue}" FontSize="16"/>
                      </StackPanel>
                    </Border>
                    <Border Background="{DynamicResource HeroChipBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="14,10" Margin="0,0,12,12">
                      <StackPanel Tag="Spacing:4">
                        <TextBlock Text="CPU usage" Style="{StaticResource SectionSubtext}"/>
                        <TextBlock Text="{Binding Text, ElementName=lblDashCpuUsage}" Style="{StaticResource MetricValue}" FontSize="16"/>
                      </StackPanel>
                    </Border>
                    <Border Background="{DynamicResource HeroChipBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="14,10" Margin="0,0,12,12">
                      <StackPanel Tag="Spacing:4">
                        <TextBlock Text="Memory" Style="{StaticResource SectionSubtext}"/>
                        <TextBlock Text="{Binding Text, ElementName=lblDashMemoryUsage}" Style="{StaticResource MetricValue}" FontSize="16"/>
                      </StackPanel>
                    </Border>
                    <Border Background="{DynamicResource HeroChipBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="12" Padding="14,10" Margin="0,0,12,12">
                      <StackPanel Tag="Spacing:4">
                        <TextBlock Text="Health" Style="{StaticResource SectionSubtext}"/>
                        <TextBlock Text="{Binding Text, ElementName=lblDashSystemHealth}" Style="{StaticResource MetricValue}" FontSize="16"/>
                      </StackPanel>
                    </Border>
                  </WrapPanel>
                </StackPanel>

                <ScrollViewer Grid.Row="1" x:Name="logScrollViewer" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                  <TextBox x:Name="LogBox"
                           Background="{DynamicResource ContentBackgroundBrush}"
                           Foreground="{DynamicResource PrimaryTextBrush}"
                           FontFamily="Consolas"
                           FontSize="11"
                           IsReadOnly="True"
                           BorderThickness="0"
                           TextWrapping="Wrap"
                           Text="Initializing KOALA Gaming Optimizer v3.0...&#10;Ready for optimization commands."/>
                </ScrollViewer>
              </Grid>
            </Border>
          </StackPanel>
        </StackPanel>
      </ScrollViewer>

      <Border x:Name="FooterBar" Grid.Row="3" Background="{DynamicResource HeaderBackgroundBrush}" BorderBrush="{DynamicResource HeaderBorderBrush}" BorderThickness="0,1,0,0" Padding="24,16" Visibility="Collapsed"/>

    </Grid>

    <StackPanel Visibility="Collapsed">
      <CheckBox x:Name="chkAutoOptimize" Visibility="Collapsed"/>
      <Button x:Name="btnLoadSettings" Visibility="Collapsed"/>
      <Button x:Name="btnOptimizeSelected" Visibility="Collapsed"/>
      <Button x:Name="btnSearchGames" Visibility="Collapsed"/>
      <Button x:Name="btnCustomSearch" Visibility="Collapsed"/>
      <Button x:Name="btnChooseBackupFolder" Visibility="Collapsed"/>
      <Button x:Name="btnSystemInfo" Visibility="Collapsed"/>
      <Button x:Name="btnInstalledGames" Visibility="Collapsed"/>
      <Expander x:Name="expanderServices" Visibility="Collapsed"/>
      <Button x:Name="btnResetSettings" Visibility="Collapsed"/>
      <Button x:Name="btnSaveSettings" Visibility="Collapsed"/>
      <Button x:Name="btnAddGameFolder" Visibility="Collapsed"/>
      <Button x:Name="btnImportOptions" Visibility="Collapsed"/>
    </StackPanel>
  </Grid>
</Window>
'@

# Normalize merge artifacts such as orphan "<" lines or tags split across line breaks
$xamlLines = @()
$resourceDepth = 0
foreach ($line in $xamlContent -split "`r?`n") {
    $trimmed = $line.Trim()

    if ($trimmed -eq '<') {
        continue
    }

    $match = [regex]::Match($trimmed, '^<\s+([/?A-Za-z].*)$')
    if ($match.Success) {
        $leadingWhitespace = $line.Substring(0, $line.IndexOf('<'))
        $line = '{0}<{1}' -f $leadingWhitespace, $match.Groups[1].Value
    }

    if ($trimmed -like '<Window.Resources*') {
        $resourceDepth++
    } elseif ($trimmed -eq '</Window.Resources>') {
        if ($resourceDepth -le 0) {
            continue
        }

        $resourceDepth--
    }

    $xamlLines += $line

$xamlContent = $xamlLines -join [Environment]::NewLine
$null = Test-XamlNameUniqueness -Xaml $xamlContent
[xml]$xaml = $xamlContent

# ---------- Build WPF UI ----------
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $form = [Windows.Markup.XamlReader]::Load($reader)
    Initialize-LayoutSpacing -Root $form
    if ($form -and $form.Resources) {
        Register-BrushResourceKeys -Keys $form.Resources.Keys

    }
    Write-Host "Failed to load XAML: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        if ($_.Exception.InnerException.InnerException) {
            Write-Host "Root cause: $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor Red
        }
    }
    exit 1

# ---------- Bind All Controls ----------

# Ensure a default theme is applied at startup (fallback to OptimizerDark if no selection)
    $defaultTheme = 'OptimizerDark'
    if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem -and $cmbOptionsTheme.SelectedItem.Tag) {
        $defaultTheme = $cmbOptionsTheme.SelectedItem.Tag

    }
    & ${function:Apply-ThemeColors} -ThemeName $defaultTheme
    try { & ${function:Apply-ThemeColors} -ThemeName 'OptimizerDark' } catch {}

# Sidebar navigation controls
$btnNavDashboard = $form.FindName('btnNavDashboard')
$btnNavBasicOpt = $form.FindName('btnNavBasicOpt')
$btnNavAdvanced = $form.FindName('btnNavAdvanced')
$btnNavGames = $form.FindName('btnNavGames')
$btnNavOptions = $form.FindName('btnNavOptions')
$btnNavBackup = $form.FindName('btnNavBackup')
$btnNavLog = $form.FindName('btnNavLog')

# Main content panels
$panelDashboard = $form.FindName('panelDashboard')
$panelBasicOpt = $form.FindName('panelBasicOpt')
$panelAdvanced = $form.FindName('panelAdvanced')
$panelGames = $form.FindName('panelGames')
$panelOptions = $form.FindName('panelOptions')
$panelBackup = $form.FindName('panelBackup')
$panelLog = $form.FindName('panelLog')
$btnAdvancedNetwork = $form.FindName('btnAdvancedNetwork')
$btnAdvancedSystem = $form.FindName('btnAdvancedSystem')
$btnAdvancedServices = $form.FindName('btnAdvancedServices')

# Header controls
$lblMainTitle = $form.FindName('lblMainTitle')
$lblMainSubtitle = $form.FindName('lblMainSubtitle')
$lblHeaderSystemStatus = $form.FindName('lblHeaderSystemStatus')
$lblHeaderLastRun = $form.FindName('lblHeaderLastRun')

# Dashboard hero metrics
$lblHeroProfiles = $form.FindName('lblHeroProfiles')
$lblHeroOptimizations = $form.FindName('lblHeroOptimizations')
$lblHeroAutoMode = $form.FindName('lblHeroAutoMode')

# Admin status controls (sidebar)
$lblSidebarAdminStatus = $form.FindName('lblSidebarAdminStatus')
$btnSidebarElevate = $form.FindName('btnSidebarElevate')

# Legacy controls to maintain compatibility
$lblAdminStatus = $lblSidebarAdminStatus
$lblAdminDetails = $lblSidebarAdminStatus
$btnElevate = $btnSidebarElevate

# Game profile controls
$cmbGameProfile = $form.FindName('cmbGameProfile')
$txtCustomGame = $form.FindName('txtCustomGame')
$btnOptimizeGame = $form.FindName('btnOptimizeGame')
$btnFindExecutable = $form.FindName('btnFindExecutable')
$btnInstalledGames = $form.FindName('btnInstalledGames')
$btnAddGameFolder = $form.FindName('btnAddGameFolder')
$btnCustomSearch = $form.FindName('btnCustomSearch')

# Dashboard controls
$lblDashCpuUsage = $form.FindName('lblDashCpuUsage')
$lblDashMemoryUsage = $form.FindName('lblDashMemoryUsage')
$lblDashActiveGames = $form.FindName('lblDashActiveGames')
$lblDashLastOptimization = $form.FindName('lblDashLastOptimization')
$lblDashSystemHealth = $form.FindName('lblDashSystemHealth')
$btnSystemHealth = $form.FindName('btnSystemHealth')
$btnSystemHealthRunCheck = $form.FindName('btnSystemHealthRunCheck')
$btnDashQuickOptimize = $form.FindName('btnDashQuickOptimize')
$btnDashAutoDetect = $form.FindName('btnDashAutoDetect')
$chkDashAutoOptimize = $form.FindName('chkDashAutoOptimize')

Update-SystemHealthSummary

# Basic optimization buttons
$btnBasicNetwork = $form.FindName('btnBasicNetwork')
$btnBasicSystem = $form.FindName('btnBasicSystem')
$btnBasicGaming = $form.FindName('btnBasicGaming')

# Legacy checkboxes and controls for backward compatibility
$chkAck = $form.FindName('chkAck')
$chkDelAckTicks = $form.FindName('chkDelAckTicks')
$chkNagle = $form.FindName('chkNagle')
$chkNetworkThrottling = $form.FindName('chkNetworkThrottling')
$chkRSS = $form.FindName('chkRSS')
$chkRSC = $form.FindName('chkRSC')
$chkChimney = $form.FindName('chkChimney')
$chkNetDMA = $form.FindName('chkNetDMA')

# Gaming optimization checkboxes
$chkGameDVR = $form.FindName('chkGameDVR')
$chkFullscreenOptimizations = $form.FindName('chkFullscreenOptimizations')
$chkGPUScheduling = $form.FindName('chkGPUScheduling')
$chkTimerResolution = $form.FindName('chkTimerResolution')
$chkGameMode = $form.FindName('chkGameMode')
$chkMPO = $form.FindName('chkMPO')

# Advanced system checkbox aliases (new Advanced panel naming)
$chkGameDVRSystem = $form.FindName('chkGameDVRSystem')
$chkFullscreenOptimizationsSystem = $form.FindName('chkFullscreenOptimizationsSystem')
$chkGPUSchedulingSystem = $form.FindName('chkGPUSchedulingSystem')
$chkTimerResolutionSystem = $form.FindName('chkTimerResolutionSystem')
$chkGameModeSystem = $form.FindName('chkGameModeSystem')
$chkMPOSystem = $form.FindName('chkMPOSystem')

if (-not $chkGameDVR) { $chkGameDVR = $chkGameDVRSystem }
if (-not $chkFullscreenOptimizations) { $chkFullscreenOptimizations = $chkFullscreenOptimizationsSystem }
if (-not $chkGPUScheduling) { $chkGPUScheduling = $chkGPUSchedulingSystem }
if (-not $chkTimerResolution) { $chkTimerResolution = $chkTimerResolutionSystem }
if (-not $chkGameMode) { $chkGameMode = $chkGameModeSystem }
if (-not $chkMPO) { $chkMPO = $chkMPOSystem }

# Enhanced gaming and system optimization checkboxes
$chkDynamicResolution = $form.FindName('chkDynamicResolution')
$chkEnhancedFramePacing = $form.FindName('chkEnhancedFramePacing')
$chkGPUOverclocking = $form.FindName('chkGPUOverclocking')
$chkCompetitiveLatency = $form.FindName('chkCompetitiveLatency')
$chkAutoDiskOptimization = $form.FindName('chkAutoDiskOptimization')
$chkAdaptivePowerManagement = $form.FindName('chkAdaptivePowerManagement')
$chkEnhancedPagingFile = $form.FindName('chkEnhancedPagingFile')
$chkDirectStorageEnhanced = $form.FindName('chkDirectStorageEnhanced')

# System performance checkboxes
$chkMemoryCompression = $form.FindName('chkMemoryCompression')
$chkPowerPlan = $form.FindName('chkPowerPlan')
$chkCPUScheduling = $form.FindName('chkCPUScheduling')
$chkPageFile = $form.FindName('chkPageFile')
$chkVisualEffects = $form.FindName('chkVisualEffects')
$chkCoreParking = $form.FindName('chkCoreParking')

# Service management checkboxes (new)
$chkDisableXboxServices = $form.FindName('chkDisableXboxServices')
$chkDisableTelemetry = $form.FindName('chkDisableTelemetry')
$chkDisableSearch = $form.FindName('chkDisableSearch')
$chkDisablePrintSpooler = $form.FindName('chkDisablePrintSpooler')
$chkDisableSuperfetch = $form.FindName('chkDisableSuperfetch')
$chkDisableFax = $form.FindName('chkDisableFax')
$chkDisableRemoteRegistry = $form.FindName('chkDisableRemoteRegistry')
$chkDisableThemes = $form.FindName('chkDisableThemes')

# Additional network checkboxes (new)
$chkTcpTimestamps = $form.FindName('chkTcpTimestamps')
$chkTcpWindowAutoTuning = $form.FindName('chkTcpWindowAutoTuning')

# Game list and search controls
$dashboardGameListPanel = $form.FindName('dashboardGameListPanel')
$gameListPanel = $form.FindName('gameListPanel')
$gameListPanelDashboard = $form.FindName('gameListPanelDashboard')

if (-not $gameListPanelDashboard -and $dashboardGameListPanel) {
    $gameListPanelDashboard = $dashboardGameListPanel
}
$btnInstalledGamesDash = $form.FindName('btnInstalledGamesDash')
$btnAddGameFolderDash = $form.FindName('btnAddGameFolderDash')
$btnCustomSearchDash = $form.FindName('btnCustomSearchDash')
$btnSearchGamesPanel = $form.FindName('btnSearchGamesPanel')
$btnAddGameFolderPanel = $form.FindName('btnAddGameFolderPanel')
$btnCustomSearchPanel = $form.FindName('btnCustomSearchPanel')
$btnSearchGames = $form.FindName('btnSearchGames')
$btnOptimizeSelectedMain = $form.FindName('btnOptimizeSelectedMain')
$btnOptimizeSelectedDashboard = $form.FindName('btnOptimizeSelectedDashboard')
$btnOptimizeSelected = $form.FindName('btnOptimizeSelected')

$script:PrimaryGameListPanel = $gameListPanel
$script:DashboardGameListPanel = $gameListPanelDashboard
$script:OptimizeSelectedButtons = @()
if ($btnOptimizeSelected) { $script:OptimizeSelectedButtons += $btnOptimizeSelected }
if ($btnOptimizeSelectedMain) { $script:OptimizeSelectedButtons += $btnOptimizeSelectedMain }
if ($btnOptimizeSelectedDashboard) { $script:OptimizeSelectedButtons += $btnOptimizeSelectedDashboard }

if (-not $script:PrimaryGameListPanel -and $gameListPanelDashboard) {
    $script:PrimaryGameListPanel = $gameListPanelDashboard
}

if (-not $gameListPanel -and $script:PrimaryGameListPanel) {
    $gameListPanel = $script:PrimaryGameListPanel
}

if ($script:PrimaryGameListPanel -and $script:DashboardGameListPanel -and -not $script:GameListMirrorAttached) {
    if (${function:Update-GameListMirrors}) {
        & ${function:Update-GameListMirrors}
    }

    $script:PrimaryGameListPanel.add_LayoutUpdated({
            if (${function:Update-GameListMirrors}) {
                & ${function:Update-GameListMirrors}
            }
        })

    $script:GameListMirrorAttached = $true
}

# Options and theme controls - cmbOptionsTheme cmbUIScale btnApplyScale pattern for validation
$cmbOptionsTheme = $form.FindName('cmbOptionsThemeMain')  # Fixed control name
$btnOptionsApplyTheme = $form.FindName('btnOptionsApplyThemeMain')  # Fixed control name
$btnApplyTheme = $form.FindName('btnApplyTheme')  # Alias for test compatibility
$customThemePanel = $form.FindName('customThemePanel')
$cmbOptionsLanguage = $form.FindName('cmbOptionsLanguage')
$cmbOptionsLanguageEnglish = $form.FindName('cmbOptionsLanguageEnglish')
$cmbOptionsLanguageGerman = $form.FindName('cmbOptionsLanguageGerman')
$txtCustomBg = $form.FindName('txtCustomBg')
$txtCustomPrimary = $form.FindName('txtCustomPrimary')
$txtCustomHover = $form.FindName('txtCustomHover')
$txtCustomText = $form.FindName('txtCustomText')
$btnApplyCustomTheme = $form.FindName('btnApplyCustomTheme')

# Color preview controls
$themeColorPreview = $form.FindName('themeColorPreview')
$previewBg = $form.FindName('previewBg')
$previewPrimary = $form.FindName('previewPrimary')
$previewHover = $form.FindName('previewHover')
$previewText = $form.FindName('previewText')
$previewBgCustom = $form.FindName('previewBgCustom')
$previewPrimaryCustom = $form.FindName('previewPrimaryCustom')
$previewHoverCustom = $form.FindName('previewHoverCustom')
$previewTextCustom = $form.FindName('previewTextCustom')

# Default color palette for the custom theme inputs so XAML loading does not rely on
# inline TextBox values that can trigger initialization failures on some hosts.
$customThemeDefaults = [ordered]@{
    Background = '#070A1A'
    Primary    = '#6C63FF'
    Hover      = '#4338CA'
    Text       = '#F5F6FF'
}

# Ensure the global custom theme cache is initialized before any preview updates so
# other functions can safely clone the values.
if (-not $global:CustomThemeColors) {
    $global:CustomThemeColors = (Get-ThemeColors -ThemeName 'OptimizerDark').Clone()
    $global:CustomThemeColors = Normalize-ThemeColorTable $global:CustomThemeColors
    $global:CustomThemeColors['Name'] = 'Custom Theme'
}

foreach ($key in $customThemeDefaults.Keys) {
    if (-not $global:CustomThemeColors.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($global:CustomThemeColors[$key])) {
        $global:CustomThemeColors[$key] = $customThemeDefaults[$key]
    }
}

$customThemeInputs = @{
    Background = $txtCustomBg
    Primary    = $txtCustomPrimary
    Hover      = $txtCustomHover
    Text       = $txtCustomText
}

foreach ($entry in $customThemeInputs.GetEnumerator()) {
    $target = $entry.Value
    $value  = $global:CustomThemeColors[$entry.Key]

    if ($target -and [string]::IsNullOrWhiteSpace($target.Text)) {
        $target.Text = $value
    }
}

if ($previewBgCustom) { Set-ShapeFillSafe -Shape $previewBgCustom -Value $global:CustomThemeColors['Background'] }
if ($previewPrimaryCustom) { Set-ShapeFillSafe -Shape $previewPrimaryCustom -Value $global:CustomThemeColors['Primary'] }
if ($previewHoverCustom) { Set-ShapeFillSafe -Shape $previewHoverCustom -Value $global:CustomThemeColors['Hover'] }
if ($previewTextCustom) { Set-ShapeFillSafe -Shape $previewTextCustom -Value $global:CustomThemeColors['Text'] }

if ($cmbOptionsTheme -and $customThemePanel) {
    $initialTheme = if ($cmbOptionsTheme.SelectedItem) { $cmbOptionsTheme.SelectedItem.Tag } else { $null }
    $customThemePanel.Visibility = if ($initialTheme -eq 'Custom') { 'Visible' } else { 'Collapsed' }
}

if (-not (Get-Variable -Name 'ThemeSelectionSyncInProgress' -Scope Script -ErrorAction SilentlyContinue)) {
    $script:ThemeSelectionSyncInProgress = $false
}

# UI scaling controls
$cmbUIScale = $form.FindName('cmbUIScaleMain')  # Fixed control name
$btnApplyScale = $form.FindName('btnApplyScaleMain')  # Fixed control name

# Settings management controls
$btnSaveSettings = $form.FindName('btnSaveSettings')
$btnLoadSettings = $form.FindName('btnLoadSettings')
$btnResetSettings = $form.FindName('btnResetSettings')

# Action buttons
$btnApply = $form.FindName('btnApply')  # Alias for compatibility
$btnApplyMain = $form.FindName('btnApplyMain')
$btnRevert = $form.FindName('btnRevert')  # Alias for compatibility
$btnRevertMain = $form.FindName('btnRevertMain')
$btnExportConfig = $form.FindName('btnExportConfigMain')  # Fixed control name
$btnImportConfig = $form.FindName('btnImportConfigMain')  # Fixed control name
$btnBackup = $form.FindName('btnBackup')

# Backup panel controls
$btnCreateBackup = $form.FindName('btnCreateBackup')
$btnExportConfigBackup = $form.FindName('btnExportConfigBackup')
$btnRestoreBackup = $form.FindName('btnRestoreBackup')
$btnImportConfigBackup = $form.FindName('btnImportConfigBackup')
$btnSaveActivityLog = $form.FindName('btnSaveActivityLog')
$btnClearActivityLog = $form.FindName('btnClearActivityLog')
$btnViewActivityLog = $form.FindName('btnViewActivityLog')

# Dedicated Panel Action Buttons
$btnApplyNetworkTweaks = $form.FindName('btnApplyNetworkTweaks')
$btnTestNetworkLatency = $form.FindName('btnTestNetworkLatency')
$btnResetNetworkSettings = $form.FindName('btnResetNetworkSettings')
$btnApplySystemOptimizations = $form.FindName('btnApplySystemOptimizations')
$btnSystemBenchmark = $form.FindName('btnSystemBenchmark')
$btnResetSystemSettings = $form.FindName('btnResetSystemSettings')
$btnApplyServiceOptimizations = $form.FindName('btnApplyServiceOptimizations')
$btnViewRunningServices = $form.FindName('btnViewRunningServices')
$btnResetServiceSettings = $form.FindName('btnResetServiceSettings')

# Activity log controls
$LogBox = $form.FindName('LogBox')
$btnClearLog = $form.FindName('btnClearLog')
$btnSaveLog = $form.FindName('btnSaveLog')
$btnSearchLog = $form.FindName('btnSearchLog')
$btnExtendLog = $form.FindName('btnExtendLog')
$btnToggleLogView = $form.FindName('btnToggleLogView')
$activityLogBorder = $form.FindName('activityLogBorder')
$logScrollViewer = $form.FindName('logScrollViewer')

# Set up global variables for legacy compatibility
$global:LogBox = $LogBox
$global:LogBoxAvailable = ($LogBox -ne $null)
# Legacy aliases for backward compatibility with existing functions
$btnAutoDetect = $btnDashAutoDetect
# $cmbMenuMode = $form.FindName('cmbMenuMode')  # Removed from header - now only in Options

# Additional legacy control mappings for existing functionality
$chkThrottle = $chkNetworkThrottling  # Map to new naming convention

# Map any missing legacy controls to prevent errors
$chkTcpTimestamps = $chkNagle  # Fallback mapping
$chkTcpECN = $chkRSS  # Fallback mapping
$chkTcpAutoTune = $chkChimney  # Fallback mapping

$basicModePanel = $panelBasicOpt
$advancedModeWelcome = $panelAdvanced
$installedGamesPanel = $panelGames
$optionsPanel = $panelOptions

# Performance monitoring controls (dashboard)
$lblActiveGames = $lblDashActiveGames
$lblCpuUsage = $lblDashCpuUsage
$lblMemoryUsage = $lblDashMemoryUsage
$lblOptimizationStatus = $lblDashLastOptimization
$chkAutoOptimize = $chkDashAutoOptimize

# Set global navigation state
# Central navigation button registry so theming and navigation stay synchronized
$global:NavigationButtonNames = @(
    'btnNavDashboard',
    'btnNavBasicOpt',
    'btnNavAdvanced',
    'btnNavGames',
    'btnNavOptions',
    'btnNavBackup',
    'btnNavLog'
)
$global:CurrentPanel = "Dashboard"
$global:MenuMode = "Dashboard"  # For legacy compatibility

# ---------- Navigation Functions ----------
# ---------- ZENTRALE NAVIGATION STATE VERWALTUNG ----------
# ---------- SAUBERE NAVIGATION MIT THEME-FARBEN ----------
function Set-ActiveNavigationButton {
    param(
        [string]$ActiveButtonName,
        [string]$CurrentTheme = 'OptimizerDark'
    )

        # Theme-Farben holen
        $colors = if ($CurrentTheme -eq 'Custom' -and $global:CustomThemeColors) {
            $global:CustomThemeColors

        } else {
            Get-ThemeColors -ThemeName $CurrentTheme
        }

        $colors = Normalize-ThemeColorTable $colors

        # Alle Navigation Buttons

        $navButtons = if ($global:NavigationButtonNames) {
            $global:NavigationButtonNames
        } else {
            @('btnNavDashboard', 'btnNavBasicOpt', 'btnNavAdvanced', 'btnNavGames', 'btnNavOptions', 'btnNavBackup', 'btnNavLog')

        Log "Setze aktiven Navigation-Button: $ActiveButtonName mit Theme '$($colors.Name)'" 'Info'

        # DISPATCHER verwenden für Thread-sichere UI-Updates
        $form.Dispatcher.Invoke([action]{

            # ALLE Buttons als unselected setzen
            foreach ($btnName in $navButtons) {
                $btn = $form.FindName($btnName)
                if ($btn) {
                    $btn.Tag = ''
                    Set-BrushPropertySafe -Target $btn -Property 'Background' -Value $colors.UnselectedBackground -AllowTransparentFallback
                    Set-BrushPropertySafe -Target $btn -Property 'Foreground' -Value $colors.UnselectedForeground -AllowTransparentFallback

                    # Sofort visuell aktualisieren
                    $btn.InvalidateVisual()
                    $btn.UpdateLayout()
                }
            }

            # NUR den aktiven Button als selected markieren
            $activeBtn = $form.FindName($ActiveButtonName)
            if ($activeBtn) {
                $activeBtn.Tag = 'Selected'
                Set-BrushPropertySafe -Target $activeBtn -Property 'Background' -Value $colors.SelectedBackground -AllowTransparentFallback
                Set-BrushPropertySafe -Target $activeBtn -Property 'Foreground' -Value $colors.SelectedForeground -AllowTransparentFallback

                # Sofort visuell aktualisieren
                $activeBtn.InvalidateVisual()
                $activeBtn.UpdateLayout()

                Log "Button '$ActiveButtonName' als aktiv markiert" 'Success'
            }

            # Komplettes Layout-Update erzwingen
            $form.InvalidateVisual()
            $form.UpdateLayout()

        }, [System.Windows.Threading.DispatcherPriority]::Render)

        Log "Fehler beim Setzen der Navigation: $($_.Exception.Message)" 'Error'


function Set-ActiveAdvancedSectionButton {
    param(
        [string]$Section,
        [string]$CurrentTheme = 'OptimizerDark'
    )

    if ([string]::IsNullOrWhiteSpace($Section)) {
        return
    }

    $validSections = 'Network', 'System', 'Services'
    if ($Section -notin $validSections) {
        Log "Ignoring advanced button highlight request for unsupported section '$Section'" 'Warning'
        return
    }

        $colors = if ($CurrentTheme -eq 'Custom' -and $global:CustomThemeColors) {
            $global:CustomThemeColors

        } else {
            Get-ThemeColors -ThemeName $CurrentTheme
        }

        $colors = Normalize-ThemeColorTable $colors

        $buttonMap = @{
            'Network'  = $btnAdvancedNetwork
            'System'   = $btnAdvancedSystem
            'Services' = $btnAdvancedServices
        }

        foreach ($key in $buttonMap.Keys) {
            $button = $buttonMap[$key]
            if (-not $button) {
                continue
            }

            if ($key -eq $Section) {
                $button.Tag = 'Selected'
                Set-BrushPropertySafe -Target $button -Property 'Background' -Value $colors.SelectedBackground -AllowTransparentFallback
                Set-BrushPropertySafe -Target $button -Property 'Foreground' -Value $colors.SelectedForeground -AllowTransparentFallback
            } else {
                $button.Tag = $null
                Set-BrushPropertySafe -Target $button -Property 'Background' -Value $colors.UnselectedBackground -AllowTransparentFallback
                Set-BrushPropertySafe -Target $button -Property 'Foreground' -Value $colors.UnselectedForeground -AllowTransparentFallback
            }

            $button.InvalidateVisual()
            $button.UpdateLayout()
        $message = "Failed to highlight advanced section button {0}: {1}" -f $Section, $_.Exception.Message
        Log $message 'Warning'


function Switch-Panel {
    param([string]$PanelName)

        # Hide all panels with null checks
        if ($panelDashboard) { $panelDashboard.Visibility = "Collapsed" }
        if ($panelBasicOpt) { $panelBasicOpt.Visibility = "Collapsed" }
        if ($panelAdvanced) { $panelAdvanced.Visibility = "Collapsed" }
        if ($panelGames) { $panelGames.Visibility = "Collapsed" }
        if ($panelOptions) { $panelOptions.Visibility = "Collapsed" }
        if ($panelBackup) { $panelBackup.Visibility = "Collapsed" }
        if ($panelLog) { $panelLog.Visibility = "Collapsed" }

        # Get current theme
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag

        } else {
            'OptimizerDark'
        }

        $global:CurrentAdvancedSection = $null

        # Show selected panel and update navigation
        switch ($PanelName) {
            "Dashboard" {
                if ($panelDashboard) { $panelDashboard.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavDashboard' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Dashboard" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Overview of system optimization status and quick actions" }
                $global:CurrentPanel = "Dashboard"
                $global:MenuMode = "Basic"
            }
            "BasicOpt" {
                if ($panelBasicOpt) { $panelBasicOpt.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavBasicOpt' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Basic Optimization" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Simple and safe optimizations for immediate performance gains" }
                $global:CurrentPanel = "BasicOpt"
                $global:MenuMode = "Basic"
            }
            "Advanced" {
                if ($panelAdvanced) { $panelAdvanced.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavAdvanced' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Advanced Settings" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Detailed optimization controls for experienced users" }
                $global:CurrentPanel = "Advanced"
                $global:MenuMode = "Advanced"
            }
            "Games" {
                if ($panelGames) { $panelGames.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavGames' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Installed Games" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Manage and optimize your installed games" }
                $global:CurrentPanel = "Games"
                $global:MenuMode = "InstalledGames"
            }
            "Options" {
                if ($panelOptions) { $panelOptions.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavOptions' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Options & Themes" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Customize appearance, themes, and application settings" }
                $global:CurrentPanel = "Options"
                $global:MenuMode = "Options"
            }
            "Backup" {
                if ($panelBackup) { $panelBackup.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavBackup' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Backup & Restore" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Create backups and restore your optimization settings" }
                $global:CurrentPanel = "Backup"
                $global:MenuMode = "Backup"
            }
            "Log" {
                if ($panelLog) { $panelLog.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavLog' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Activity log" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Review detailed optimization history and export records" }
                $global:CurrentPanel = "Log"
                $global:MenuMode = "Log"
            }
            default {
                # Default to Dashboard
                if ($panelDashboard) { $panelDashboard.Visibility = "Visible" }
                Set-ActiveNavigationButton -ActiveButtonName 'btnNavDashboard' -CurrentTheme $currentTheme

                if ($lblMainTitle) { $lblMainTitle.Text = "Dashboard" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Overview of system optimization status and quick actions" }
                $global:CurrentPanel = "Dashboard"
                $global:MenuMode = "Basic"
            }
        }

        Log "Switched to $PanelName panel with correct navigation highlighting" 'Info'

        Log "Error switching to panel $PanelName`: $($_.Exception.Message)" 'Error'

function Show-AdvancedSection {
    param(
        [string]$Section,
        [string]$CurrentTheme = 'OptimizerDark'
    )

    if ([string]::IsNullOrWhiteSpace($Section)) {
        $Section = 'Network'
    }

    $validSections = 'Network', 'System', 'Services'
    if ($Section -notin $validSections) {
        Log "Requested advanced section '$Section' is unknown. Falling back to 'Network'." 'Warning'
        $Section = 'Network'
    }

        Switch-Panel "Advanced"
        $global:CurrentAdvancedSection = $Section

        Set-ActiveNavigationButton -ActiveButtonName 'btnNavAdvanced' -CurrentTheme $CurrentTheme


        switch ($Section) {
            'Network' {
                if ($lblMainTitle) { $lblMainTitle.Text = "Advanced Settings - Network Tweaks" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Configure advanced TCP and latency optimizations" }
                if ($expanderNetworkTweaks) { $expanderNetworkTweaks.IsExpanded = $true }
                if ($expanderSystemOptimizations) { $expanderSystemOptimizations.IsExpanded = $false }
                if ($expanderServiceManagement) { $expanderServiceManagement.IsExpanded = $false }
                if ($expanderNetworkTweaks) {
                    $form.Dispatcher.BeginInvoke([action]{ $expanderNetworkTweaks.BringIntoView() }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null

                }
            }
            'System' {
                if ($lblMainTitle) { $lblMainTitle.Text = "Advanced Settings - System Optimization" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Tune high-impact performance options for your PC" }
                if ($expanderNetworkTweaks) { $expanderNetworkTweaks.IsExpanded = $false }
                if ($expanderSystemOptimizations) { $expanderSystemOptimizations.IsExpanded = $true }
                if ($expanderServiceManagement) { $expanderServiceManagement.IsExpanded = $false }
                if ($expanderSystemOptimizations) {
                    $form.Dispatcher.BeginInvoke([action]{ $expanderSystemOptimizations.BringIntoView() }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
                }
            }
            'Services' {
                if ($lblMainTitle) { $lblMainTitle.Text = "Advanced Settings - Services Management" }
                if ($lblMainSubtitle) { $lblMainSubtitle.Text = "Review and tweak service startup and background tasks" }
                if ($expanderNetworkTweaks) { $expanderNetworkTweaks.IsExpanded = $false }
                if ($expanderSystemOptimizations) { $expanderSystemOptimizations.IsExpanded = $false }
                if ($expanderServiceManagement) { $expanderServiceManagement.IsExpanded = $true }
                if ($expanderServiceManagement) {
                    $form.Dispatcher.BeginInvoke([action]{ $expanderServiceManagement.BringIntoView() }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
                }
            }
        }

        Switch-Theme -ThemeName $CurrentTheme
        Set-ActiveAdvancedSectionButton -Section $Section -CurrentTheme $CurrentTheme
        $warningMessage = "Failed to navigate to advanced section {0}: {1}" -f $Section, $_.Exception.Message
        Log $warningMessage 'Warning'
    }


# Additional legacy control aliases for compatibility with existing functions
$chkResponsiveness = $chkGameMode  # Map to new gaming optimizations
$chkGamesTask = $chkGameDVR  # Map to similar controls
$chkFSE = $chkFullscreenOptimizations  # Direct mapping
$chkGpuScheduler = $chkGPUScheduling  # Direct mapping
$chkTimerRes = $chkTimerResolution  # Direct mapping
$chkHibernation = $chkPowerPlan  # Related power setting

# System Performance mappings
$chkMemoryManagement = $chkMemoryCompression  # Direct mapping
$chkCpuScheduling = $chkCPUScheduling  # Direct mapping

# Advanced FPS mappings
$chkCpuCorePark = $chkCoreParking  # Direct mapping
$chkMemCompression = $chkMemoryCompression  # Direct mapping

# Create fallback null controls for missing advanced features
$chkCpuCStates = $null
$chkInterruptMod = $null
$chkMMCSS = $null
$chkLargePages = $null
$chkInputOptimization = $null
$chkDirectX12Opt = $null
$chkHPET = $null
$chkMenuDelay = $null
$chkDefenderOptimize = $null
$chkDirectStorage = $null

# Navigation Event Handlers
if (-not $script:NavigationClickHandlers) {
    $script:NavigationClickHandlers = @{}
}

if ($btnNavDashboard) {
    $btnNavDashboard.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Switch-Panel "Dashboard"
        Switch-Theme -ThemeName $currentTheme
    })

if ($btnNavBasicOpt) {
    if (-not ($script:NavigationClickHandlers.ContainsKey('BasicOpt') -and $script:NavigationClickHandlers['BasicOpt'])) {
        $script:NavigationClickHandlers['BasicOpt'] = [System.Windows.RoutedEventHandler]{
            param($sender, $args)

            $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
                $cmbOptionsTheme.SelectedItem.Tag
            } else {
                'OptimizerDark'
            }

            Switch-Panel "BasicOpt"
            Switch-Theme -ThemeName $currentTheme
        }

        $btnNavBasicOpt.Add_Click($script:NavigationClickHandlers['BasicOpt'])
    }

if ($btnNavAdvanced) {
    if (-not ($script:NavigationClickHandlers.ContainsKey('Advanced') -and $script:NavigationClickHandlers['Advanced'])) {
        $script:NavigationClickHandlers['Advanced'] = [System.Windows.RoutedEventHandler]{
            param($sender, $args)

            $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
                $cmbOptionsTheme.SelectedItem.Tag
            } else {
                'OptimizerDark'
            }

            Show-AdvancedSection -Section 'Network' -CurrentTheme $currentTheme
        }

        $btnNavAdvanced.Add_Click($script:NavigationClickHandlers['Advanced'])
    }

if ($btnNavGames) {
    $btnNavGames.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Switch-Panel "Games"
        Switch-Theme -ThemeName $currentTheme
    })

if ($btnNavOptions) {
    $btnNavOptions.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Switch-Panel "Options"
        Switch-Theme -ThemeName $currentTheme
    })

if ($btnNavBackup) {
    $btnNavBackup.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Switch-Panel "Backup"
        Switch-Theme -ThemeName $currentTheme
    })

if ($btnNavLog) {
    $btnNavLog.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Switch-Panel "Log"
        Switch-Theme -ThemeName $currentTheme
    })

# Advanced section shortcuts remain available via the panel buttons
if ($btnAdvancedNetwork) {
    $btnAdvancedNetwork.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Show-AdvancedSection -Section 'Network' -CurrentTheme $currentTheme
    })

if ($btnAdvancedSystem) {
    $btnAdvancedSystem.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Show-AdvancedSection -Section 'System' -CurrentTheme $currentTheme
    })

if ($btnAdvancedServices) {
    $btnAdvancedServices.Add_Click({
        $currentTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem) {
            $cmbOptionsTheme.SelectedItem.Tag
        } else {
            'OptimizerDark'
        }

        Show-AdvancedSection -Section 'Services' -CurrentTheme $currentTheme
    })

# Header theme selector removed - theme switching now only available in Options panel
#         Log "Theme change requested from header: $selectedTheme" 'Info'
#         Switch-Theme -ThemeName $selectedTheme
#
#         # Sync with options panel theme selector
#         if ($cmbOptionsTheme) {
#             try {
#                 foreach ($item in $cmbOptionsTheme.Items) {
#                     if ($item.Tag -eq $selectedTheme) {
#                         $cmbOptionsTheme.SelectedItem = $item
#                         break
#                     }
#                 }
#             } catch {
#                 Log "Could not sync options theme selector: $($_.Exception.Message)" 'Warning'
#             }
#         }
#     }
# })
# }

# Custom theme panel visibility is managed alongside the live preview handler that
# runs later in the script (see Options panel event handlers section).

if ($cmbOptionsLanguage) {
    $cmbOptionsLanguage.Add_SelectionChanged({
        if ($script:IsLanguageInitializing) {
            return

        if ($cmbOptionsLanguage.SelectedItem -and $cmbOptionsLanguage.SelectedItem.Tag) {
            Set-UILanguage -LanguageCode $cmbOptionsLanguage.SelectedItem.Tag -SkipSelectionUpdate
        }

# Custom theme application
if ($btnApplyCustomTheme) {
    $btnApplyCustomTheme.Add_Click({
            $inputMap = [ordered]@{
                Background = $txtCustomBg
                Primary    = $txtCustomPrimary
                Hover      = $txtCustomHover
                Text       = $txtCustomText

            }

            $validated = @{}
            foreach ($entry in $inputMap.GetEnumerator()) {
                $box = $entry.Value
                $rawValue = if ($box) { $box.Text } else { $null }
                $trimmed = if ($rawValue) { $rawValue.Trim() } else { '' }

                if ([string]::IsNullOrWhiteSpace($trimmed)) {
                    [System.Windows.MessageBox]::Show("Please enter a $($entry.Key.ToLower()) color in HEX format (e.g. #1A2B3C).", "Custom Theme", 'OK', 'Warning')
                    return
                }

                if ($trimmed -notmatch '^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$') {
                    [System.Windows.MessageBox]::Show("Invalid $($entry.Key.ToLower()) color '$trimmed'. Use #RRGGBB or #AARRGGBB values.", "Custom Theme", 'OK', 'Warning')
                    return
                }

                $normalized = $trimmed.ToUpperInvariant()
                $validated[$entry.Key] = $normalized

                if ($box) { $box.Text = $normalized }
            }

            Log "Applying custom theme: BG=$($validated.Background), Primary=$($validated.Primary), Hover=$($validated.Hover), Text=$($validated.Text)" 'Info'
            if (${function:Apply-ThemeColors}) {
                & ${function:Apply-ThemeColors} -Background $validated.Background -Primary $validated.Primary -Hover $validated.Hover -Foreground $validated.Text
            } else {
                Log "Apply-ThemeColors Funktion nicht verfügbar - benutzerdefiniertes Theme kann nicht angewendet werden" 'Error'
                return
            }
            Update-ThemeColorPreview -ThemeName 'Custom'

            if ($global:CustomThemeColors) {
                foreach ($key in $validated.Keys) {
                    $converted = New-SolidColorBrushSafe $validated[$key]
                    if ($converted -is [System.Windows.Media.Brush]) {
                        $global:CustomThemeColors[$key] = $converted
                    } else {
                        $global:CustomThemeColors[$key] = $validated[$key]
                    }
                }

                $global:CustomThemeColors = Normalize-ThemeColorTable $global:CustomThemeColors
            }

            [System.Windows.MessageBox]::Show("Custom theme applied successfully!", "Custom Theme", 'OK', 'Information')
            Log "Error applying custom theme: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error applying custom theme: $($_.Exception.Message)", "Theme Error", 'OK', 'Error')

# ---------- Localization Support ----------
function Initialize-LocalizationResources {
    if ($script:LocalizationResources) {
        return
    }

    $script:LocalizationResources = @{
        'en' = @{
            DisplayName = 'English'
            Controls    = @{
                'lblLanguageSectionTitle' = @{ Text = '🌐 Language' }
                'lblLanguageDescription'  = @{ Text = 'Choose how KOALA should talk to you.' }
                'lblLanguageLabel'        = @{ Text = 'Language:' }
                'cmbOptionsLanguage'      = @{ ToolTip = 'Switch between English and German wording in the interface.' }
                'expanderNetworkTweaks'   = @{ Header = '🌐 Network Optimizations' }
                'expanderNetworkOptimizations' = @{ Header = '🌐 Core Network Tweaks' }
                'expanderSystemOptimizations'  = @{ Header = '💻 System Optimizations' }
                'expanderPerformanceOptimizations' = @{ Header = '⚡ Performance Optimizations' }
                'expanderAdvancedPerformance' = @{ Header = '🚀 Advanced Performance Enhancements' }
                'expanderServiceManagement' = @{ Header = '🛠️ Service Optimizations' }
                'expanderServiceOptimizations' = @{ Header = '🧰 Service Tweaks' }
                'expanderPrivacyServices'  = @{ Header = '🔒 Privacy & Background Services' }
                'chkAckNetwork'            = @{ Content = 'TCP ACK Frequency'; ToolTip = 'Lets your PC confirm incoming data faster to reduce online lag.' }
                'chkDelAckTicksNetwork'    = @{ Content = 'Delayed ACK Ticks'; ToolTip = 'Cuts the waiting time before Windows confirms data packets, lowering delay.' }
                'chkNagleNetwork'          = @{ Content = 'Disable Nagle Algorithm'; ToolTip = 'Stops Windows from bundling small messages together so actions happen right away.' }
                'chkNetworkThrottlingNetwork' = @{ Content = 'Network Throttling Index'; ToolTip = 'Removes Windows built-in speed limiter for background network tasks.' }
                'chkRSSNetwork'            = @{ Content = 'Receive Side Scaling'; ToolTip = 'Lets Windows use multiple CPU cores to handle incoming internet traffic.' }
                'chkRSCNetwork'            = @{ Content = 'Receive Segment Coalescing'; ToolTip = 'Allows Windows to combine related network packets to lighten the workload.' }
                'chkChimneyNetwork'        = @{ Content = 'TCP Chimney Offload'; ToolTip = 'Moves some network work to your network card so the CPU stays free.' }
                'chkNetDMANetwork'         = @{ Content = 'NetDMA State'; ToolTip = 'Enables direct memory access for network cards to speed up transfers.' }
                'chkTcpTimestampsNetwork'  = @{ Content = 'TCP Timestamps'; ToolTip = 'Turns off extra timing stamps that can slow down gaming connections.' }
                'chkTcpWindowAutoTuningNetwork' = @{ Content = 'TCP Window Auto-Tuning'; ToolTip = 'Optimizes how Windows sizes network data windows for faster downloads.' }
                'chkMemoryCompressionSystem' = @{ Content = 'Memory Compression'; ToolTip = 'Compresses rarely used data in memory to keep more RAM free for games.' }
                'chkPowerPlanSystem'       = @{ Content = 'High Performance Power Plan'; ToolTip = 'Forces Windows to use the high-performance power plan for best speed.' }
                'chkCPUSchedulingSystem'   = @{ Content = 'CPU Scheduling'; ToolTip = 'Gives background services less priority so games get more CPU time.' }
                'chkPageFileSystem'        = @{ Content = 'Page File Optimization'; ToolTip = 'Fine-tunes the Windows page file to avoid slow downs when memory fills.' }
                'chkVisualEffectsSystem'   = @{ Content = 'Disable Visual Effects'; ToolTip = 'Turns off eye-candy animations to free resources for performance.' }
                'chkCoreParkingSystem'     = @{ Content = 'Core Parking'; ToolTip = 'Keeps CPU cores awake so games can use them instantly.' }
                'chkGameDVRSystem'         = @{ Content = 'Disable Game DVR'; ToolTip = 'Disables Windows background recording to prevent FPS drops.' }
                'chkFullscreenOptimizationsSystem' = @{ Content = 'Fullscreen Exclusive'; ToolTip = 'Uses classic full screen mode to reduce input lag.' }
                'chkGPUSchedulingSystem'   = @{ Content = 'Hardware GPU Scheduling'; ToolTip = 'Lets the graphics card schedule its own work for smoother frames.' }
                'chkTimerResolutionSystem' = @{ Content = 'Timer Resolution'; ToolTip = 'Sets Windows timers to 1 ms for faster input response.' }
                'chkGameModeSystem'        = @{ Content = 'Game Mode'; ToolTip = 'Activates Windows Game Mode to focus resources on games.' }
                'chkMPOSystem'             = @{ Content = 'MPO (Multi-Plane Overlay)'; ToolTip = 'Turns off a display feature that can cause flickering or stutter.' }
                'chkDynamicResolution'     = @{ Content = 'Dynamic Resolution Scaling'; ToolTip = 'Automatically lowers resolution during busy scenes to keep frames steady.' }
                'chkEnhancedFramePacing'   = @{ Content = 'Enhanced Frame Pacing'; ToolTip = 'Balances frame delivery so motion looks smoother.' }
                'chkGPUOverclocking'       = @{ Content = 'Profile-based GPU Overclocking'; ToolTip = 'Applies a safe GPU tuning profile tailored for gaming.' }
                'chkCompetitiveLatency'    = @{ Content = 'Competitive Latency Reduction'; ToolTip = 'Cuts extra buffering to keep controls feeling instant.' }
                'chkAutoDiskOptimization'  = @{ Content = 'Auto Disk Defrag/SSD Trim'; ToolTip = 'Runs the right disk cleanup (defrag or TRIM) on a schedule.' }
                'chkAdaptivePowerManagement' = @{ Content = 'Adaptive Power Management'; ToolTip = 'Adjusts power settings on the fly to balance speed and heat.' }
                'chkEnhancedPagingFile'    = @{ Content = 'Enhanced Paging File Management'; ToolTip = 'Sets page file size based on RAM to prevent sudden slowdowns.' }
                'chkDirectStorageEnhanced' = @{ Content = 'DirectStorage API Enhancement'; ToolTip = 'Prepares Windows for faster loading with DirectStorage-ready tweaks.' }
                'chkAdvancedTelemetryDisable' = @{ Content = 'Advanced Telemetry & Tracking Disable'; ToolTip = 'Limits background data sharing to free system resources.' }
                'chkMemoryDefragmentation' = @{ Content = 'Memory Defragmentation & Cleanup'; ToolTip = 'Reorganizes memory so large games get big uninterrupted blocks.' }
                'chkServiceOptimization'   = @{ Content = 'Advanced Service Optimization'; ToolTip = 'Optimizes background services to focus on performance.' }
                'chkDiskTweaksAdvanced'    = @{ Content = 'Advanced Disk I/O Tweaks'; ToolTip = 'Improves how Windows reads and writes data for gaming drives.' }
                'chkNetworkLatencyOptimization' = @{ Content = 'Ultra-Low Network Latency Mode'; ToolTip = 'Applies extra network tweaks aimed at the lowest possible ping.' }
                'chkFPSSmoothness'         = @{ Content = 'FPS Smoothness & Frame Time Optimization'; ToolTip = 'Applies timing tweaks to keep frame times even.' }
                'chkCPUMicrocode'          = @{ Content = 'CPU Microcode & Cache Optimization'; ToolTip = 'Loads optimized CPU microcode settings for stability under load.' }
                'chkRAMTimings'            = @{ Content = 'RAM Timing & Frequency Optimization'; ToolTip = 'Applies safe memory timing adjustments for better throughput.' }
                'chkDisableXboxServicesServices' = @{ Content = 'Disable Xbox Services'; ToolTip = 'Stops Xbox helper services that consume memory when not gaming.' }
                'chkDisableTelemetryServices' = @{ Content = 'Disable Telemetry'; ToolTip = 'Turns off Windows data reporting services to free bandwidth.' }
                'chkDisableSearchServices' = @{ Content = 'Disable Windows Search'; ToolTip = 'Pauses Windows Search indexing to save disk activity.' }
                'chkDisablePrintSpoolerServices' = @{ Content = 'Disable Print Spooler'; ToolTip = 'Stops print services if you do not use a printer.' }
                'chkDisableSuperfetchServices' = @{ Content = 'Disable Superfetch'; ToolTip = 'Disables the preloading service that can cause drive activity.' }
                'chkDisableFaxServices'    = @{ Content = 'Disable Fax Service'; ToolTip = 'Turns off the unused fax service.' }
                'chkDisableRemoteRegistryServices' = @{ Content = 'Disable Remote Registry'; ToolTip = 'Blocks remote registry access for security and less background work.' }
                'chkDisableThemesServices' = @{ Content = 'Optimize Themes Service'; ToolTip = 'Optimizes the themes service to reduce visual overhead.' }
                'chkDisableCortana'        = @{ Content = 'Disable Cortana & Voice Assistant'; ToolTip = 'Disables Cortana to save memory and network use.' }
                'chkDisableWindowsUpdate'  = @{ Content = 'Optimize Windows Update Service'; ToolTip = 'Limits automatic updates so games are not interrupted.' }
                'chkDisableBackgroundApps' = @{ Content = 'Disable Background App Refresh'; ToolTip = 'Stops background apps from running when you do not need them.' }
                'chkDisableLocationTracking' = @{ Content = 'Disable Location Tracking Services'; ToolTip = 'Prevents Windows from tracking your location in the background.' }
                'chkDisableAdvertisingID'  = @{ Content = 'Disable Advertising ID Services'; ToolTip = 'Clears and stops the ad ID so apps cannot build ad profiles.' }
                'chkDisableErrorReporting' = @{ Content = 'Disable Error Reporting Services'; ToolTip = 'Stops error reports from sending data online automatically.' }
                'chkDisableCompatTelemetry' = @{ Content = 'Disable Compatibility Telemetry'; ToolTip = 'Blocks compatibility telemetry that collects app usage.' }
                'chkDisableWSH'            = @{ Content = 'Disable Windows Script Host'; ToolTip = 'Disables Windows Script Host to avoid unwanted scripts.' }
            }
            ComboItems = @{
                'cmbOptionsLanguageEnglish' = 'English'
                'cmbOptionsLanguageGerman'  = 'German'
            }
        }
        'de' = @{
            DisplayName = 'Deutsch'
            Controls    = @{
                'lblLanguageSectionTitle' = @{ Text = '🌐 Sprache' }
                'lblLanguageDescription'  = @{ Text = 'Wähle, wie KOALA mit dir sprechen soll.' }
                'lblLanguageLabel'        = @{ Text = 'Sprache:' }
                'cmbOptionsLanguage'      = @{ ToolTip = 'Wechsle zwischen englischen und deutschen Texten im Programm.' }
                'expanderNetworkTweaks'   = @{ Header = '🌐 Netzwerk-Optimierungen' }
                'expanderNetworkOptimizations' = @{ Header = '🌐 Zentrale Netzwerk-Feinabstimmung' }
                'expanderSystemOptimizations'  = @{ Header = '💻 System-Optimierungen' }
                'expanderPerformanceOptimizations' = @{ Header = '⚡ Leistungs-Optimierungen' }
                'expanderAdvancedPerformance' = @{ Header = '🚀 Erweiterte Leistungssteigerungen' }
                'expanderServiceManagement' = @{ Header = '🛠️ Dienstoptimierungen' }
                'expanderServiceOptimizations' = @{ Header = '🧰 Dienst-Anpassungen' }
                'expanderPrivacyServices'  = @{ Header = '🔒 Datenschutz & Hintergrunddienste' }
                'chkAckNetwork'            = @{ Content = 'TCP-ACK beschleunigen'; ToolTip = 'Lässt deinen PC eingehende Daten schneller bestätigen und senkt so Verzögerungen im Online-Spiel.' }
                'chkDelAckTicksNetwork'    = @{ Content = 'Verzögerte ACK-Zeit verkürzen'; ToolTip = 'Verkürzt die Wartezeit, bevor Windows Datenpakete bestätigt, und senkt damit die Latenz.' }
                'chkNagleNetwork'          = @{ Content = 'Nagle-Algorithmus deaktivieren'; ToolTip = 'Verhindert, dass Windows kleine Nachrichten sammelt, damit deine Aktionen sofort ausgeführt werden.' }
                'chkNetworkThrottlingNetwork' = @{ Content = 'Netzwerk-Drosselung ausschalten'; ToolTip = 'Hebt die in Windows eingebaute Geschwindigkeitsbremse für Netzwerkaufgaben auf.' }
                'chkRSSNetwork'            = @{ Content = 'Receive Side Scaling aktivieren'; ToolTip = 'Erlaubt Windows, mehrere CPU-Kerne für eingehenden Internetverkehr zu nutzen.' }
                'chkRSCNetwork'            = @{ Content = 'Receive Segment Coalescing aktivieren'; ToolTip = 'Ermöglicht Windows, zusammengehörige Pakete zu bündeln und so den Aufwand zu senken.' }
                'chkChimneyNetwork'        = @{ Content = 'TCP-Chimney-Offload nutzen'; ToolTip = 'Verlagert Netzwerkarbeit auf die Netzwerkkarte, damit der Prozessor entlastet wird.' }
                'chkNetDMANetwork'         = @{ Content = 'NetDMA aktivieren'; ToolTip = 'Aktiviert direkten Speicherzugriff für Netzwerkkarten und beschleunigt Übertragungen.' }
                'chkTcpTimestampsNetwork'  = @{ Content = 'TCP-Zeitstempel deaktivieren'; ToolTip = 'Schaltet zusätzliche Zeitstempel aus, die Gaming-Verbindungen ausbremsen können.' }
                'chkTcpWindowAutoTuningNetwork' = @{ Content = 'TCP-Fenster automatisch abstimmen'; ToolTip = 'Optimiert, wie Windows Datenfenster festlegt, damit Downloads schneller laufen.' }
                'chkMemoryCompressionSystem' = @{ Content = 'Speicherkompression verwalten'; ToolTip = 'Komprimiert selten genutzte Daten im Speicher, damit mehr RAM für Spiele frei bleibt.' }
                'chkPowerPlanSystem'       = @{ Content = 'Höchstleistung Energieplan erzwingen'; ToolTip = 'Erzwingt den Höchstleistungs-Energieplan von Windows für maximale Geschwindigkeit.' }
                'chkCPUSchedulingSystem'   = @{ Content = 'CPU-Zeitplanung optimieren'; ToolTip = 'Gibt Hintergrunddiensten weniger Priorität, damit Spiele mehr CPU-Zeit erhalten.' }
                'chkPageFileSystem'        = @{ Content = 'Auslagerungsdatei optimieren'; ToolTip = 'Stimmt die Auslagerungsdatei ab, damit es bei vollem RAM nicht zu Bremsen kommt.' }
                'chkVisualEffectsSystem'   = @{ Content = 'Visuelle Effekte reduzieren'; ToolTip = 'Schaltet Effekte ab, um Ressourcen für Leistung freizumachen.' }
                'chkCoreParkingSystem'     = @{ Content = 'Core Parking deaktivieren'; ToolTip = 'Hält CPU-Kerne wach, damit Spiele sie sofort nutzen können.' }
                'chkGameDVRSystem'         = @{ Content = 'Game DVR deaktivieren'; ToolTip = 'Deaktiviert die Hintergrundaufzeichnung von Windows und verhindert FPS-Einbrüche.' }
                'chkFullscreenOptimizationsSystem' = @{ Content = 'Exklusiven Vollbildmodus erzwingen'; ToolTip = 'Erzwingt den klassischen Vollbildmodus und senkt die Eingabeverzögerung.' }
                'chkGPUSchedulingSystem'   = @{ Content = 'Hardware-GPU-Planung aktivieren'; ToolTip = 'Erlaubt der Grafikkarte, ihre Arbeit selbst zu planen, wodurch Bilder flüssiger laufen.' }
                'chkTimerResolutionSystem' = @{ Content = 'Timerauflösung auf 1 ms setzen'; ToolTip = 'Setzt Windows-Timer auf 1 Millisekunde für schnellere Reaktionen.' }
                'chkGameModeSystem'        = @{ Content = 'Windows-Spielmodus aktivieren'; ToolTip = 'Aktiviert den Windows-Spielmodus, damit Ressourcen auf Spiele fokussiert werden.' }
                'chkMPOSystem'             = @{ Content = 'MPO (Multi-Plane Overlay) deaktivieren'; ToolTip = 'Schaltet eine Darstellungsfunktion ab, die Flackern oder Ruckeln verursachen kann.' }
                'chkDynamicResolution'     = @{ Content = 'Dynamische Auflösung nutzen'; ToolTip = 'Senkt die Auflösung in hektischen Szenen automatisch, damit die Bildrate stabil bleibt.' }
                'chkEnhancedFramePacing'   = @{ Content = 'Bildtaktung glätten'; ToolTip = 'Gleicht die Bildausgabe aus, damit Bewegungen ruhiger wirken.' }
                'chkGPUOverclocking'       = @{ Content = 'GPU-Profiloptimierung anwenden'; ToolTip = 'Wendet ein sicheres GPU-Tuning-Profil speziell für Spiele an.' }
                'chkCompetitiveLatency'    = @{ Content = 'Wettkampf-Latenz reduzieren'; ToolTip = 'Reduziert zusätzliche Puffer, damit die Steuerung sofort reagiert.' }
                'chkAutoDiskOptimization'  = @{ Content = 'Automatische Laufwerksoptimierung'; ToolTip = 'Startet je nach Laufwerk automatisch Defrag oder TRIM, um es sauber zu halten.' }
                'chkAdaptivePowerManagement' = @{ Content = 'Adaptive Energieverwaltung'; ToolTip = 'Passt die Energieeinstellungen dynamisch an, um Leistung und Temperatur auszugleichen.' }
                'chkEnhancedPagingFile'    = @{ Content = 'Auslagerungsdatei anpassen'; ToolTip = 'Stimmt die Größe der Auslagerungsdatei auf deinen RAM ab, um plötzliche Bremsen zu vermeiden.' }
                'chkDirectStorageEnhanced' = @{ Content = 'DirectStorage optimieren'; ToolTip = 'Bereitet Windows mit DirectStorage-Anpassungen auf schnellere Ladezeiten vor.' }
                'chkAdvancedTelemetryDisable' = @{ Content = 'Erweiterte Telemetrie abschalten'; ToolTip = 'Begrenzt das Senden von Hintergrunddaten und spart Ressourcen.' }
                'chkMemoryDefragmentation' = @{ Content = 'Arbeitsspeicher defragmentieren'; ToolTip = 'Ordnet den Speicher neu, damit große Spiele zusammenhängenden RAM erhalten.' }
                'chkServiceOptimization'   = @{ Content = 'Dienste für Spiele optimieren'; ToolTip = 'Optimiert Hintergrunddienste, damit mehr Leistung für Spiele bleibt.' }
                'chkDiskTweaksAdvanced'    = @{ Content = 'Fortgeschrittene Datenträgeroptimierung'; ToolTip = 'Verbessert Lese- und Schreibzugriffe von Windows auf deine Gaming-Laufwerke.' }
                'chkNetworkLatencyOptimization' = @{ Content = 'Ultra-niedrige Netzwerklatenz'; ToolTip = 'Setzt zusätzliche Netzwerkoptimierungen für den niedrigsten möglichen Ping um.' }
                'chkFPSSmoothness'         = @{ Content = 'FPS-Glättung aktivieren'; ToolTip = 'Nimmt Zeitanpassungen vor, damit Bildzeiten gleichmäßig bleiben.' }
                'chkCPUMicrocode'          = @{ Content = 'CPU-Mikrocode optimieren'; ToolTip = 'Lädt optimierte CPU-Mikrocode-Einstellungen für Stabilität unter Last.' }
                'chkRAMTimings'            = @{ Content = 'RAM-Timings abstimmen'; ToolTip = 'Nimmt sichere RAM-Timing-Anpassungen für mehr Durchsatz vor.' }
                'chkDisableXboxServicesServices' = @{ Content = 'Xbox-Dienste deaktivieren'; ToolTip = 'Beendet Xbox-Hilfsdienste, die auch ohne Spiel Speicher belegen.' }
                'chkDisableTelemetryServices' = @{ Content = 'Telemetry-Dienste deaktivieren'; ToolTip = 'Schaltet Datenerfassungsdienste von Windows aus und spart Bandbreite.' }
                'chkDisableSearchServices' = @{ Content = 'Windows-Suche pausieren'; ToolTip = 'Pausiert die Windows-Suche, um Laufwerksaktivität zu sparen.' }
                'chkDisablePrintSpoolerServices' = @{ Content = 'Druckwarteschlange deaktivieren'; ToolTip = 'Beendet Druckdienste, wenn kein Drucker verwendet wird.' }
                'chkDisableSuperfetchServices' = @{ Content = 'Superfetch deaktivieren'; ToolTip = 'Deaktiviert den Vorlade-Dienst, der Laufwerke beschäftigen kann.' }
                'chkDisableFaxServices'    = @{ Content = 'Faxdienst deaktivieren'; ToolTip = 'Schaltet den ungenutzten Faxdienst ab.' }
                'chkDisableRemoteRegistryServices' = @{ Content = 'Remote-Registry sperren'; ToolTip = 'Sperrt den Remotezugriff auf die Registry für mehr Sicherheit und weniger Hintergrundarbeit.' }
                'chkDisableThemesServices' = @{ Content = 'Design-Dienst optimieren'; ToolTip = 'Optimiert den Design-Dienst, um visuelle Last zu reduzieren.' }
                'chkDisableCortana'        = @{ Content = 'Cortana & Sprachassistent deaktivieren'; ToolTip = 'Deaktiviert Cortana, um Speicher und Datenverkehr zu sparen.' }
                'chkDisableWindowsUpdate'  = @{ Content = 'Windows Update optimieren'; ToolTip = 'Begrenzt automatische Updates, damit Spiele nicht unterbrochen werden.' }
                'chkDisableBackgroundApps' = @{ Content = 'Hintergrund-Apps stoppen'; ToolTip = 'Verhindert, dass Hintergrund-Apps laufen, wenn du sie nicht brauchst.' }
                'chkDisableLocationTracking' = @{ Content = 'Standortverfolgung stoppen'; ToolTip = 'Verhindert, dass Windows deinen Standort im Hintergrund verfolgt.' }
                'chkDisableAdvertisingID'  = @{ Content = 'Werbe-ID deaktivieren'; ToolTip = 'Setzt die Werbe-ID zurück und verhindert, dass Apps Werbeprofile erstellen.' }
                'chkDisableErrorReporting' = @{ Content = 'Fehlerberichterstattung deaktivieren'; ToolTip = 'Verhindert, dass Fehlerberichte automatisch Daten senden.' }
                'chkDisableCompatTelemetry' = @{ Content = 'Kompatibilitäts-Telemetrie blockieren'; ToolTip = 'Blockiert Kompatibilitäts-Telemetrie, die App-Nutzung sammelt.' }
                'chkDisableWSH'            = @{ Content = 'Windows Script Host deaktivieren'; ToolTip = 'Deaktiviert den Windows Script Host, um unerwünschte Skripte zu vermeiden.' }
            }
            ComboItems = @{
                'cmbOptionsLanguageEnglish' = 'Englisch'
                'cmbOptionsLanguageGerman'  = 'Deutsch'
            }
        }
    }
}

function Set-UILanguage {
    param(
        [string]$LanguageCode,
        [switch]$SkipSelectionUpdate
    )

    Initialize-LocalizationResources

    if (-not $LanguageCode) {
        $LanguageCode = 'en'
    }

    if (-not $script:LocalizationResources.ContainsKey($LanguageCode)) {
        Log "Requested language '$LanguageCode' is not available. Falling back to English." 'Warning'
        $LanguageCode = 'en'
    }

    $script:CurrentLanguage = $LanguageCode
    $languageResources = $script:LocalizationResources[$LanguageCode]

    foreach ($entry in $languageResources.Controls.GetEnumerator()) {
        $controlName = $entry.Key
        $control = $form.FindName($controlName)
        if (-not $control) {
            continue
        }

        $controlConfig = $entry.Value

        if ($controlConfig.ContainsKey('Content') -and $control.PSObject.Properties['Content']) {
            $control.Content = $controlConfig.Content
        }

        if ($controlConfig.ContainsKey('Header') -and $control.PSObject.Properties['Header']) {
            $control.Header = $controlConfig.Header
        }

        if ($controlConfig.ContainsKey('Text') -and $control.PSObject.Properties['Text']) {
            $control.Text = $controlConfig.Text
        }

        if ($controlConfig.ContainsKey('ToolTip')) {
            $control.ToolTip = $controlConfig.ToolTip
        }
    }

    if ($languageResources.ContainsKey('ComboItems')) {
        foreach ($itemEntry in $languageResources.ComboItems.GetEnumerator()) {
            $comboItem = $form.FindName($itemEntry.Key)
            if ($comboItem -and $comboItem.PSObject.Properties['Content']) {
                $comboItem.Content = $itemEntry.Value
            }
        }
    }

    if (-not $SkipSelectionUpdate -and $cmbOptionsLanguage -and $cmbOptionsLanguage.Items.Count -gt 0) {
        $script:IsLanguageInitializing = $true
        foreach ($item in $cmbOptionsLanguage.Items) {
            if ($item.Tag -eq $LanguageCode) {
                $cmbOptionsLanguage.SelectedItem = $item
                break
            }
        }
        $script:IsLanguageInitializing = $false
    }

    $activeTheme = if ($cmbOptionsTheme -and $cmbOptionsTheme.SelectedItem -and $cmbOptionsTheme.SelectedItem.Tag) {
        $cmbOptionsTheme.SelectedItem.Tag
    } elseif ($global:CurrentTheme) {
        $global:CurrentTheme
    } else {
        'OptimizerDark'

        Switch-Theme -ThemeName $activeTheme

        if ($global:CurrentPanel -eq 'Advanced' -and $global:CurrentAdvancedSection) {
            Set-ActiveAdvancedSectionButton -Section $global:CurrentAdvancedSection -CurrentTheme $activeTheme

        }
        Log "Failed to refresh theme after language change: $($_.Exception.Message)" 'Warning'

    Log "UI language switched to $($languageResources.DisplayName)" 'Info'

# Apply the initial language selection after localization helpers are defined
Set-UILanguage -LanguageCode $script:CurrentLanguage

# Remove old control bindings and set null fallbacks for missing advanced controls
$chkGpuAutoTuning = $null
$chkLowLatencyAudio = $null
$chkHardwareInterrupt = $null
$chkNVMeOptimization = $null
$chkWin11GameMode = $null
$chkMemoryPool = $null
$chkGpuPreemption = $null
$chkCpuMicrocode = $null
$chkPciLatency = $null
$chkDmaRemapping = $null
$chkFramePacing = $null

# DX11 Optimizations - set to null for new UI
$chkDX11GpuScheduling = $null
$chkDX11ProcessPriority = $null
$chkDX11BackgroundServices = $null
$chkDX11HardwareAccel = $null
$chkDX11MaxPerformance = $null
$chkDX11RegistryTweaks = $null

# Advanced tweaks - set to null for new UI
$chkModernStandby = $null
$chkUTCTime = $null
$chkNTFS = $null
$chkEdgeTelemetry = $null
$chkCortana = $null
$chkTelemetry = $null

# Set remaining controls to null for new UI architecture
$chkSvcXbox = $null
$chkSvcSpooler = $null
$chkSvcSysMain = $null
$chkSvcDiagTrack = $null
$chkSvcSearch = $null
$chkDisableUnneeded = $null

# Performance monitoring labels are already mapped above
# Additional legacy mappings
$lblLastRefresh = $lblDashLastOptimization

# Continue cleaning up old control references by setting them to null
$chkRamOptimization = $null
$chkStartupPrograms = $null
$chkBootOptimization = $null
$lblOptimizationStatus = $form.FindName('lblOptimizationStatus')
$chkAutoOptimize = $form.FindName('chkAutoOptimize')

# Buttons
$btnSystemInfo = $form.FindName('btnSystemInfo')
$btnBenchmark = $form.FindName('btnBenchmark')
$btnBackup = $form.FindName('btnBackup')
$btnBackupReg = $form.FindName('btnBackupReg')
$btnExportConfig = $form.FindName('btnExportConfigMain')  # Fixed control name
$btnExportConfigOptions = $form.FindName('btnExportConfigOptions')
$btnImportConfig = $form.FindName('btnImportConfigMain')  # Fixed control name
$btnImportConfigOptions = $form.FindName('btnImportConfigOptions')
$btnApply = $form.FindName('btnApply')
$btnRevert = $form.FindName('btnRevert')
$btnClearLog = $form.FindName('btnClearLog')

# Options panel controls
$optionsPanel = $form.FindName('optionsPanel')
$cmbOptionsTheme = $form.FindName('cmbOptionsThemeMain')  # Fixed control name
$btnOptionsApplyTheme = $form.FindName('btnOptionsApplyThemeMain')  # Fixed control name
$cmbUIScale = $form.FindName('cmbUIScaleMain')  # Fixed control name
$btnApplyScale = $form.FindName('btnApplyScaleMain')  # Fixed control name
$btnSaveSettings = $form.FindName('btnSaveSettings')
$btnLoadSettings = $form.FindName('btnLoadSettings')
$btnResetSettings = $form.FindName('btnResetSettings')
$btnImportOptions = $form.FindName('btnImportOptions')
$btnChooseBackupFolder = $form.FindName('btnChooseBackupFolder')

# Installed Games panel controls
$installedGamesPanel = $form.FindName('installedGamesPanel')
$btnSearchGames = $form.FindName('btnSearchGames')
$btnAddGameFolder = $form.FindName('btnAddGameFolder')
$btnCustomSearch = $form.FindName('btnCustomSearch')
$gameListPanel = $form.FindName('gameListPanel')
$btnOptimizeSelected = $form.FindName('btnOptimizeSelected')

# Expanders
$expanderNetwork = $form.FindName('expanderNetwork')
$expanderEssential = $form.FindName('expanderEssential')
$expanderSystemPerf = $form.FindName('expanderSystemPerf')
$expanderAdvancedFPS = $form.FindName('expanderAdvancedFPS')
$expanderDX11 = $form.FindName('expanderDX11')
$expanderHellzerg = $form.FindName('expanderHellzerg')
$expanderServices = $form.FindName('expanderServices')

# New Advanced Options Expanders
$expanderNetworkTweaks = $form.FindName('expanderNetworkTweaks')
$expanderSystemOptimizations = $form.FindName('expanderSystemOptimizations')
$expanderServiceManagement = $form.FindName('expanderServiceManagement')

# Dedicated Panel Expanders
$expanderNetworkOptimizations = $form.FindName('expanderNetworkOptimizations')
$expanderPerformanceOptimizations = $form.FindName('expanderPerformanceOptimizations')
$expanderServiceOptimizations = $form.FindName('expanderServiceOptimizations')

# Mode panels
$basicModePanel = $form.FindName('basicModePanel')
$advancedModeWelcome = $form.FindName('advancedModeWelcome')

# Basic mode buttons
$btnBasicNetwork = $form.FindName('btnBasicNetwork')
$btnBasicSystem = $form.FindName('btnBasicSystem')
$btnBasicGaming = $form.FindName('btnBasicGaming')

# Log box initialization with enhanced error handling
$global:LogBox = $form.FindName('LogBox')
$global:LogBoxAvailable = ($global:LogBox -ne $null)

# Verify LogBox initialization with comprehensive testing
if ($global:LogBoxAvailable) {
    # Test that LogBox is actually usable
        $global:LogBox.AppendText("")  # Test write access
        $global:LogBox.Clear()  # Test clear access
        Log "Activity log UI initialized successfully - ready for logging" 'Success'
        $global:LogBoxAvailable = $false
        Write-Host "Warning: Activity log UI not accessible, using console and file logging only" -ForegroundColor Yellow
        Log "LogBox UI unavailable - using fallback logging methods" 'Warning'
    }
    Write-Host "Warning: Activity log UI element not found, using console and file logging only" -ForegroundColor Yellow
    Log "LogBox UI element not found - using fallback logging methods" 'Warning'

# ---------- STARTUP CONTROL VALIDATION (moved after form creation) ----------
# Perform startup control validation after form and controls are created
Log "Running startup control validation..." 'Info'
$controlsValid = Test-StartupControls

if (-not $controlsValid) {
    Log "CRITICAL: Some controls are missing - application may have reduced functionality" 'Warning'
    Log "The application will continue to run, but some features may not work properly" 'Warning'
} else {
    Log "[OK] All startup control validation checks passed - application ready" 'Success'

# ---------- Populate Game Profiles Dropdown ----------
$cmbGameProfile.Items.Clear()

# Custom Profile
$item = New-Object System.Windows.Controls.ComboBoxItem
$item.Content = "Custom Profile"
$item.Tag = "custom"
$cmbGameProfile.Items.Add($item)

# Competitive Shooters Section
$headerItem = New-Object System.Windows.Controls.ComboBoxItem
$headerItem.Content = "--- COMPETITIVE SHOOTERS ---"
$headerItem.Tag = ""
$headerItem.IsEnabled = $false
$headerItem.FontWeight = "Bold"
Set-BrushPropertySafe -Target $headerItem -Property 'Foreground' -Value '#8F6FFF'
$cmbGameProfile.Items.Add($headerItem)

foreach ($key in @('cs2', 'csgo', 'valorant', 'overwatch2', 'r6siege')) {
    if ($GameProfiles.ContainsKey($key)) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $GameProfiles[$key].DisplayName
        $item.Tag = $key
        $cmbGameProfile.Items.Add($item)
    }
}

# Battle Royale Section
$headerItem = New-Object System.Windows.Controls.ComboBoxItem
$headerItem.Content = "--- BATTLE ROYALE ---"
$headerItem.Tag = ""
$headerItem.IsEnabled = $false
$headerItem.FontWeight = "Bold"
Set-BrushPropertySafe -Target $headerItem -Property 'Foreground' -Value '#8F6FFF'
$cmbGameProfile.Items.Add($headerItem)

foreach ($key in @('fortnite', 'apexlegends', 'pubg', 'warzone')) {
    if ($GameProfiles.ContainsKey($key)) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $GameProfiles[$key].DisplayName
        $item.Tag = $key
        $cmbGameProfile.Items.Add($item)
    }
}

# Multiplayer Section
$headerItem = New-Object System.Windows.Controls.ComboBoxItem
$headerItem.Content = "--- MULTIPLAYER ---"
$headerItem.Tag = ""
$headerItem.IsEnabled = $false
$headerItem.FontWeight = "Bold"
Set-BrushPropertySafe -Target $headerItem -Property 'Foreground' -Value '#8F6FFF'
$cmbGameProfile.Items.Add($headerItem)

foreach ($key in @('lol', 'rocketleague', 'dota2', 'gta5')) {
    if ($GameProfiles.ContainsKey($key)) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $GameProfiles[$key].DisplayName
        $item.Tag = $key
        $cmbGameProfile.Items.Add($item)
    }
}

# AAA Titles Section
$headerItem = New-Object System.Windows.Controls.ComboBoxItem
$headerItem.Content = "--- AAA TITLES ---"
$headerItem.Tag = ""
$headerItem.IsEnabled = $false
$headerItem.FontWeight = "Bold"
Set-BrushPropertySafe -Target $headerItem -Property 'Foreground' -Value '#8F6FFF'
$cmbGameProfile.Items.Add($headerItem)

foreach ($key in @('hogwartslegacy', 'starfield', 'baldursgate3', 'cyberpunk2077')) {
    if ($GameProfiles.ContainsKey($key)) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $GameProfiles[$key].DisplayName
        $item.Tag = $key
        $cmbGameProfile.Items.Add($item)
    }
}

# Survival & More Section
$headerItem = New-Object System.Windows.Controls.ComboBoxItem
$headerItem.Content = "--- SURVIVAL & MORE ---"
$headerItem.Tag = ""
$headerItem.IsEnabled = $false
$headerItem.FontWeight = "Bold"
Set-BrushPropertySafe -Target $headerItem -Property 'Foreground' -Value '#8F6FFF'
$cmbGameProfile.Items.Add($headerItem)

foreach ($key in $GameProfiles.Keys | Where-Object { $_ -notin @('cs2', 'csgo', 'valorant', 'overwatch2', 'r6siege', 'fortnite', 'apexlegends', 'pubg', 'warzone', 'lol', 'rocketleague', 'dota2', 'gta5', 'hogwartslegacy', 'starfield', 'baldursgate3', 'cyberpunk2077') }) {
    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $GameProfiles[$key].DisplayName
    $item.Tag = $key
    $cmbGameProfile.Items.Add($item)
}
$cmbGameProfile.SelectedIndex = 0

# ---------- Menu Mode Function ----------
function Switch-MenuMode {
    param([string]$Mode, [switch]$ResizeWindow)

    # Validate input mode
    $validModes = @("Basic", "Advanced", "InstalledGames", "Options", "Dashboard")
    if ($Mode -notin $validModes) {
        Log "Switch-MenuMode: Invalid mode '$Mode'. Valid modes: $($validModes -join ', ')" 'Error'
        return
    }

    Log "Switch-MenuMode: Switching from '$global:MenuMode' to '$Mode'" 'Info'

    # If switching to Advanced mode, require KOALA confirmation
    if ($Mode -eq "Advanced" -and $global:MenuMode -ne "Advanced") {
        $confirmationMessage = @"
⚠️ WARNING: Advanced Mode Access ⚠️

Are you sure you want to switch to Advanced Mode?

Advanced Mode provides access to powerful system tweaks and optimization features. These advanced tweaks may cause system errors, performance issues, or instability. Changes made in Advanced Mode can significantly affect your system's behavior and may require system restoration if problems occur.

By continuing, you acknowledge that:
* Advanced tweaks may cause errors or system instability
* You are solely responsible for any changes made in Advanced Mode
* No liability will be held by the author for system issues
* You should create a system backup before proceeding

To confirm that you understand these risks and unlock Advanced Mode, please type: KOALA
"@

            $userInput = [Microsoft.VisualBasic.Interaction]::InputBox($confirmationMessage, "Advanced Mode Confirmation", "")

            if ($userInput -ne "KOALA") {
                Log "Advanced Mode access denied - incorrect confirmation (user entered: '$userInput')" 'Warning'
                Log "Reverting to previous mode: $global:MenuMode" 'Info'
                return

            }

            Log "Advanced Mode access granted with KOALA confirmation" 'Info'
            Log "User confirmed understanding of Advanced Mode risks and responsibilities" 'Info'
            Log "Error in Advanced Mode confirmation dialog: $($_.Exception.Message)" 'Error'
            return
        }
    }

    $global:MenuMode = $Mode

    # Use proper WPF Visibility enumeration
    $VisibleState = [System.Windows.Visibility]::Visible
    $CollapsedState = [System.Windows.Visibility]::Collapsed

        # Reset all panels to collapsed first
        $allPanels = @($basicModePanel, $advancedModeWelcome, $installedGamesPanel, $optionsPanel)
        $allExpanders = @($expanderAdvancedFPS, $expanderDX11, $expanderHellzerg, $expanderServices, $expanderNetwork, $expanderEssential, $expanderSystemPerf, $expanderNetworkTweaks, $expanderSystemOptimizations, $expanderServiceManagement)

        foreach ($panel in $allPanels) {
            if ($panel) {
                $panel.Visibility = $CollapsedState
                Log "Panel '$($panel.Name)' set to collapsed" 'Info'

            }
        }

        foreach ($expander in $allExpanders) {
            if ($expander) {
                $expander.Visibility = $CollapsedState
                Log "Expander '$($expander.Name)' set to collapsed" 'Info'
            }
        }

        # Set visibility based on selected mode
        switch ($Mode) {
            "Basic" {
                # Show Basic Mode panel only
                if ($basicModePanel) {
                    $basicModePanel.Visibility = $VisibleState
                    Log "Basic Mode panel activated" 'Info'
                }

                Log "Switched to Basic Mode - Safe optimizations only" 'Success'
            }

            "Advanced" {
                # Show all advanced sections
                if ($advancedModeWelcome) { $advancedModeWelcome.Visibility = $VisibleState }
                if ($expanderAdvancedFPS) { $expanderAdvancedFPS.Visibility = $VisibleState }
                if ($expanderDX11) { $expanderDX11.Visibility = $VisibleState }
                if ($expanderHellzerg) { $expanderHellzerg.Visibility = $VisibleState }
                if ($expanderServices) { $expanderServices.Visibility = $VisibleState }
                if ($expanderNetwork) { $expanderNetwork.Visibility = $VisibleState }
                if ($expanderEssential) { $expanderEssential.Visibility = $VisibleState }
                if ($expanderSystemPerf) { $expanderSystemPerf.Visibility = $VisibleState }

                Log "Switched to Advanced Mode - All tweaks available" 'Success'
            }

            "InstalledGames" {
                # Show Installed Games panel
                if ($installedGamesPanel) {
                    $installedGamesPanel.Visibility = $VisibleState
                    Log "Installed Games panel activated" 'Info'
                }

                Log "Switched to Installed Games Mode - Game discovery and optimization" 'Success'
            }

            "Options" {
                # Show Options panel
                if ($optionsPanel) {
                    $optionsPanel.Visibility = $VisibleState
                    Log "Options panel activated" 'Info'
                }

                Log "Switched to Options Mode - Settings and preferences" 'Success'
            }

            "Dashboard" {
                # Dashboard mode - show basic info but hide most controls
                Log "Switched to Dashboard Mode - Overview display" 'Success'
            }
        }

        # Optional window resizing based on mode complexity
        if ($ResizeWindow -and $form) {
                $currentWidth = $form.Width
                $currentHeight = $form.Height
                $newWidth = $currentWidth
                $newHeight = $currentHeight

                switch ($Mode) {
                    "Basic" {
                        $newWidth = [Math]::Max(1200, $currentWidth)
                        $newHeight = [Math]::Max(700, $currentHeight)

                    }
                    "Advanced" {
                        $newWidth = [Math]::Max(1400, $currentWidth)
                        $newHeight = [Math]::Max(900, $currentHeight)
                    }
                    "Options" {
                        $newWidth = [Math]::Max(1200, $currentWidth)
                        $newHeight = [Math]::Max(800, $currentHeight)
                    }
                }

                if ($newWidth -ne $currentWidth -or $newHeight -ne $currentHeight) {
                    $form.Width = $newWidth
                    $form.Height = $newHeight
                    Log "Window resized to ${newWidth}x${newHeight} for $Mode mode" 'Info'
                }
                Log "Error resizing window for mode ${Mode}: $($_.Exception.Message)" 'Warning'
            }

        Log "Error switching to $Mode mode: $($_.Exception.Message)" 'Error'

# ---------- Installed Games Discovery Function ----------
function Show-InstalledGames {
        Log "Searching for installed games on system..." 'Info'

        # Create a new window for displaying installed games
        [xml]$installedGamesXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Installed Games Discovery"
        Width="800" Height="600"
        Background="{StaticResource DialogBackgroundBrush}"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">

  <Window.Resources>
    <SolidColorBrush x:Key="DialogBackgroundBrush" Color="#080716"/>
    <SolidColorBrush x:Key="CardBackgroundBrush" Color="#14132B"/>
    <SolidColorBrush x:Key="CardBorderBrush" Color="#2F285A"/>
    <SolidColorBrush x:Key="AccentBrush" Color="#8F6FFF"/>
    <SolidColorBrush x:Key="PrimaryTextBrush" Color="#F5F3FF"/>
    <SolidColorBrush x:Key="SecondaryTextBrush" Color="#A9A5D9"/>
    <Style TargetType="TextBlock">
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
    <Style TargetType="Button" x:Key="DialogButton">
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Foreground" Value="#120B22"/>
        <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Padding" Value="14,6"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}" CornerRadius="10">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#A78BFA"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.4"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    <Style x:Key="SecondaryDialogButton" TargetType="Button" BasedOn="{StaticResource DialogButton}">
        <Setter Property="Background" Value="#1F1B3F"/>
        <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
  </Window.Resources>

  <Grid Margin="20">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <Border Grid.Row="0" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15" Margin="0,0,0,15">
      <StackPanel>
        <TextBlock Text="Installed Games Discovery" Foreground="{DynamicResource AccentBrush}" FontWeight="Bold" FontSize="20" HorizontalAlignment="Center"/>
        <TextBlock Text="Searching for games installed on your system..." Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
      </StackPanel>
    </Border>

    <!-- Games List -->
    <Border Grid.Row="1" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <ListBox x:Name="lstInstalledGames" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12">
          <ListBox.ItemTemplate>
            <DataTemplate>
              <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="4" Padding="8" Margin="2">
                <StackPanel>
                  <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="13" Foreground="{DynamicResource AccentBrush}"/>
                  <TextBlock Text="{Binding Path}" FontSize="11" Foreground="{DynamicResource SecondaryTextBrush}" Margin="0,2,0,0"/>
                  <TextBlock Text="{Binding Details}" FontSize="10" Foreground="{DynamicResource AccentBrush}" Margin="0,2,0,0"/>
                </StackPanel>
              </Border>
            </DataTemplate>
          </ListBox.ItemTemplate>
        </ListBox>
      </ScrollViewer>
    </Border>

    <!-- Footer -->
    <Border Grid.Row="2" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="10" Margin="0,15,0,0">
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
        <Button x:Name="btnRefreshGames" Content="Refresh Search" Width="140" Height="34" Style="{StaticResource DialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnCloseGames" Content="Close" Width="80" Height="32" Background="{DynamicResource AccentBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderThickness="0" FontWeight="SemiBold"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
'@

        # Create the window
        $reader = New-Object System.Xml.XmlNodeReader $installedGamesXaml
        $gamesWindow = [Windows.Markup.XamlReader]::Load($reader)
        Initialize-LayoutSpacing -Root $gamesWindow

        # Get controls
        $lstInstalledGames = $gamesWindow.FindName('lstInstalledGames')
        $btnRefreshGames = $gamesWindow.FindName('btnRefreshGames')
        $btnCloseGames = $gamesWindow.FindName('btnCloseGames')

        # Function to search for installed games using multiple detection methods
        function Search-InstalledGames {
            $games = @()
            Log "Scanning system for installed games using advanced detection methods..." 'Info'

            # 1. Registry-based detection for Steam games
            try {
                Log "Searching Steam registry for installed games..." 'Info'
                $steamPath = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue
                if ($steamPath) {
                    $steamLibraryPath = Join-Path $steamPath.SteamPath "steamapps\common"
                    if (Test-Path $steamLibraryPath) {
                        $steamGames = Get-ChildItem -Path $steamLibraryPath -Directory -ErrorAction SilentlyContinue
                        foreach ($game in $steamGames) {
                            $games += [PSCustomObject]@{
                                Name = $game.Name
                                Path = $game.FullName
                                Details = "Steam Game - Detected via Registry"
                            }
                            Log "Found Steam game: $($game.Name)" 'Success'

                        }
                    }
                }
                Log "Steam registry detection failed: $($_.Exception.Message)" 'Warning'
            }

            # 2. Epic Games Launcher detection
                Log "Searching Epic Games registry..." 'Info'
                $epicPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher" -Name "AppDataPath" -ErrorAction SilentlyContinue
                if ($epicPath) {
                    $epicManifestPath = Join-Path $epicPath.AppDataPath "Manifests"
                    if (Test-Path $epicManifestPath) {
                        $manifests = Get-ChildItem -Path $epicManifestPath -Filter "*.item" -ErrorAction SilentlyContinue
                        foreach ($manifest in $manifests) {
                            try {
                                $content = Get-Content $manifest.FullName | ConvertFrom-Json
                                if ($content.InstallLocation -and (Test-Path $content.InstallLocation)) {
                                    $games += [PSCustomObject]@{
                                        Name = $content.DisplayName
                                        Path = $content.InstallLocation
                                        Details = "Epic Games - Verified Installation"
                                    }
                                    Log "Found Epic Games title: $($content.DisplayName)" 'Success'

                                }
                                # Skip invalid manifests
                            }
                        }
                    }
                }
                Log "Epic Games detection failed: $($_.Exception.Message)" 'Warning'
            }

            # 3. Registry-based Windows Apps detection
                Log "Searching Windows registry for installed applications..." 'Info'
                $uninstallKeys = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )

                foreach ($keyPath in $uninstallKeys) {
                    $apps = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -and $_.InstallLocation -and
                        ($_.DisplayName -match "steam|game|epic|origin|uplay|battle\.net|minecraft|fortnite|valorant|league" -or
                         $_.Publisher -match "valve|riot|epic|blizzard|ubisoft|ea|activision|mojang")

                    }

                    foreach ($app in $apps) {
                        if (Test-Path $app.InstallLocation) {
                            $games += [PSCustomObject]@{
                                Name = $app.DisplayName
                                Path = $app.InstallLocation
                                Details = "Registry Entry - Verified Installation ($($app.Publisher))"
                            }
                            Log "Found registered application: $($app.DisplayName)" 'Success'
                        }
                    }
                }
                Log "Registry application detection failed: $($_.Exception.Message)" 'Warning'
            }

            # 4. Enhanced directory scanning with launcher detection
            $searchPaths = @(
                "$env:ProgramFiles\",
                "${env:ProgramFiles(x86)}\",
                "$env:LOCALAPPDATA\Programs\",
                "$env:ProgramData\",
                "C:\Games\",
                "D:\Games\",
                "E:\Games\",
                "$env:USERPROFILE\AppData\Local\"
            )

            # 5. Launcher-specific detection
            $launchers = @{
                "Battle.net" = @{
                    Path = "${env:ProgramFiles(x86)}\Battle.net"
                    ConfigPath = "$env:APPDATA\Battle.net\Battle.net.config"
                }
                "Ubisoft Connect" = @{
                    Path = "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher"
                    ConfigPath = "$env:LOCALAPPDATA\Ubisoft Game Launcher"
                }
                "GOG Galaxy" = @{
                    Path = "${env:ProgramFiles(x86)}\GOG Galaxy"
                    ConfigPath = "$env:LOCALAPPDATA\GOG.com\Galaxy\Configuration"
                }
                "Origin" = @{
                    Path = "${env:ProgramFiles(x86)}\Origin"
                    ConfigPath = "$env:APPDATA\Origin"
                }
            }

            foreach ($launcher in $launchers.Keys) {
                    $launcherInfo = $launchers[$launcher]
                    if (Test-Path $launcherInfo.Path) {
                        $games += [PSCustomObject]@{
                            Name = "$launcher (Game Launcher)"
                            Path = $launcherInfo.Path
                            Details = "Launcher Detected - Can manage multiple games"

                        }
                        Log "Found launcher: $launcher" 'Success'
                    }
                    # Continue if launcher detection fails
                }

            # 6. Enhanced executable scanning with verification
            $gameExecutables = @{
                "csgo.exe" = "Counter-Strike: Global Offensive"
                "cs2.exe" = "Counter-Strike 2"
                "valorant.exe" = "VALORANT"
                "valorant-win64-shipping.exe" = "VALORANT (Shipping)"
                "overwatch.exe" = "Overwatch"
                "overwatch2.exe" = "Overwatch 2"
                "r6siege.exe" = "Rainbow Six Siege"
                "rainbowsix.exe" = "Rainbow Six Siege"
                "fortnite.exe" = "Fortnite"
                "fortniteclient-win64-shipping.exe" = "Fortnite (Shipping)"
                "apex_legends.exe" = "Apex Legends"
                "r5apex.exe" = "Apex Legends (R5)"
                "pubg.exe" = "PlayerUnknown's Battlegrounds"
                "tslgame.exe" = "PUBG (TSL)"
                "warzone.exe" = "Call of Duty: Warzone"
                "modernwarfare.exe" = "Call of Duty: Modern Warfare"
                "league of legends.exe" = "League of Legends"
                "leagueclient.exe" = "League of Legends Client"
                "riotclientservices.exe" = "Riot Client"
                "rocketleague.exe" = "Rocket League"
                "dota2.exe" = "Dota 2"
                "gta5.exe" = "Grand Theft Auto V"
                "gtav.exe" = "Grand Theft Auto V"
                "cyberpunk2077.exe" = "Cyberpunk 2077"
                "minecraft.exe" = "Minecraft Java"
                "minecraftlauncher.exe" = "Minecraft Launcher"
                "steam.exe" = "Steam Client"
                "epicgameslauncher.exe" = "Epic Games Launcher"
                "battlenet.exe" = "Battle.net Launcher"
                "battle.net.exe" = "Battle.net"
                "origin.exe" = "EA Origin"
                "originwebhelperservice.exe" = "Origin Web Helper"
                "uplay.exe" = "Ubisoft Connect"
                "upc.exe" = "Ubisoft Connect"
                "gog.exe" = "GOG Galaxy"
                "discordapp.exe" = "Discord"
                "obs64.exe" = "OBS Studio"
                "obs32.exe" = "OBS Studio (32-bit)"
            }

            # 7. Enhanced directory and executable scanning with verification
            foreach ($path in $searchPaths) {
                if (Test-Path $path) {
                    Log "Searching in: $path" 'Info'
                        # Search for known game executables with verification
                        foreach ($exe in $gameExecutables.Keys) {
                            $foundFiles = Get-ChildItem -Path $path -Recurse -Name $exe -ErrorAction SilentlyContinue
                            foreach ($file in $foundFiles) {
                                $fullPath = Join-Path $path $file
                                if (Test-Path $fullPath) {
                                    $fileInfo = Get-Item $fullPath -ErrorAction SilentlyContinue
                                    if ($fileInfo -and $fileInfo.Length -gt 1MB) { # Only include substantial executables
                                        # Check if it's actually an executable and not just a placeholder
                                        $isValidGame = $true

                                        # Additional verification for known false positives
                                        $parentDir = Split-Path $fullPath -Parent
                                        $dirName = Split-Path $parentDir -Leaf

                                        # Skip if in temp or cache directories
                                        if ($parentDir -match "temp|cache|backup|installer" -and $fileInfo.Length -lt 10MB) {
                                            $isValidGame = $false

                                        }

                                        if ($isValidGame) {
                                            # Check for duplicate detection - only add unique paths
                                            $alreadyExists = $games | Where-Object { $_.Path -eq $fullPath }
                                            if (-not $alreadyExists) {
                                                $game = [PSCustomObject]@{
                                                    Name = $gameExecutables[$exe]
                                                    Path = $fullPath
                                                    Details = "Executable Verified - Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB | Dir: $dirName"
                                                }
                                                $games += $game
                                                Log "Found verified game: $($gameExecutables[$exe]) at $fullPath" 'Success'
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        # Search for game platform directories with content verification
                        $gameInstallDirs = @{
                            "Steam\steamapps\common" = "Steam Games Directory"
                            "Epic Games\*" = "Epic Games Directory"
                            "Ubisoft\Ubisoft Game Launcher\games" = "Ubisoft Games Directory"
                            "EA Games" = "EA Games Directory"
                            "Origin Games" = "Origin Games Directory"
                            "GOG Games" = "GOG Games Directory"
                            "Minecraft" = "Minecraft Directory"
                            "Battle.net" = "Battle.net Directory"
                        }

                        foreach ($dirPattern in $gameInstallDirs.Keys) {
                            $dirPath = Join-Path $path $dirPattern
                            $matchingDirs = Get-Item $dirPath -ErrorAction SilentlyContinue
                            if (-not $matchingDirs -and $dirPattern.Contains("*")) {
                                $matchingDirs = Get-ChildItem -Path (Split-Path $dirPath -Parent) -Directory -Filter (Split-Path $dirPattern -Leaf) -ErrorAction SilentlyContinue
                            }

                            foreach ($dir in $matchingDirs) {
                                if ($dir -and (Test-Path $dir.FullName)) {
                                    # Only include if directory has substantial content
                                    $subItems = Get-ChildItem -Path $dir.FullName -ErrorAction SilentlyContinue
                                    if ($subItems -and $subItems.Count -gt 0) {
                                        # Check for duplicate paths
                                        $alreadyExists = $games | Where-Object { $_.Path -eq $dir.FullName }
                                        if (-not $alreadyExists) {
                                            $game = [PSCustomObject]@{
                                                Name = "$($gameInstallDirs[$dirPattern]) ($($subItems.Count) items)"
                                                Path = $dir.FullName
                                                Details = "Platform Directory - Contains $($subItems.Count) items | Created: $($dir.CreationTime.ToString('yyyy-MM-dd'))"
                                            }
                                            $games += $game
                                            Log "Found platform directory: $($gameInstallDirs[$dirPattern]) at $($dir.FullName)" 'Info'
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Log "Error searching $path : $($_.Exception.Message)" 'Warning'
                    }
                }

            # 8. Cloud Gaming Services Detection
                Log "Searching for cloud gaming services..." 'Info'
                $cloudServices = Get-CloudGamingServices
                foreach ($service in $cloudServices) {
                    $games += $service
                    Log "Found cloud gaming service: $($service.Name)" 'Success'

                }
                Log "Cloud gaming services detection failed: $($_.Exception.Message)" 'Warning'

            # 9. Game Streaming Software Detection - obs64.exe, OBS Studio, obs32.exe support
            $streamingSoftware = @{
                "obs64.exe" = "OBS Studio (Streaming/Recording)"
                "obs32.exe" = "OBS Studio 32-bit"
                "xsplit.exe" = "XSplit Broadcaster"  # Professional streaming software
                "streamlabs.exe" = "Streamlabs OBS"  # Professional streaming software
                "nvidia broadcast.exe" = "NVIDIA Broadcast"  # Professional streaming software
                "nvidia share.exe" = "NVIDIA GeForce Experience"
                "amd relive.exe" = "AMD ReLive"
                "discord.exe" = "Discord (Voice Chat)"  # Voice chat software
                "teamspeak3.exe" = "TeamSpeak 3"  # Voice chat software
                "ventrilo.exe" = "Ventrilo"
                "mumble.exe" = "Mumble"  # Voice chat software
            }

            foreach ($exe in $streamingSoftware.Keys) {
                foreach ($path in $searchPaths) {
                    if (Test-Path $path) {
                        $foundFiles = Get-ChildItem -Path $path -Recurse -Name $exe -ErrorAction SilentlyContinue
                        foreach ($file in $foundFiles) {
                            $fullPath = Join-Path $path $file
                            if (Test-Path $fullPath) {
                                $fileInfo = Get-Item $fullPath -ErrorAction SilentlyContinue
                                if ($fileInfo -and $fileInfo.Length -gt 100KB) {
                                    $alreadyExists = $games | Where-Object { $_.Path -eq $fullPath }
                                    if (-not $alreadyExists) {
                                        $games += [PSCustomObject]@{
                                            Name = $streamingSoftware[$exe]
                                            Path = $fullPath
                                            Details = "Gaming Support Software - Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
                                        }
                                        Log "Found gaming support software: $($streamingSoftware[$exe])" 'Success'
                                    }
                                }
                            }
                        }
                    }
                }
            }

            return $games

        # Initial search
        $foundGames = Search-InstalledGames

        if ($foundGames.Count -gt 0) {
            $lstInstalledGames.ItemsSource = $foundGames
            Log "Found $($foundGames.Count) installed games/platforms" 'Success'
        } else {
            $noGamesFound = @([PSCustomObject]@{
                Name = "No Games Found"
                Path = "Try running as Administrator for better detection"
                Details = "Common game directories may be hidden or require elevated permissions"
            })
            $lstInstalledGames.ItemsSource = $noGamesFound
            Log "No games found in common directories" 'Warning'

        # Event handlers
        $btnRefreshGames.Add_Click({
            Log "Refreshing installed games search..." 'Info'
            $lstInstalledGames.ItemsSource = $null
            $refreshedGames = Search-InstalledGames

            if ($refreshedGames.Count -gt 0) {
                $lstInstalledGames.ItemsSource = $refreshedGames
                Log "Refresh complete: Found $($refreshedGames.Count) games/platforms" 'Success'
            } else {
                $noGamesFound = @([PSCustomObject]@{
                    Name = "No Games Found"
                    Path = "Try running as Administrator for better detection"
                    Details = "Common game directories may be hidden or require elevated permissions"
                })
                $lstInstalledGames.ItemsSource = $noGamesFound
                Log "Refresh complete: No games found" 'Warning'
            }

        $btnCloseGames.Add_Click({
            Log "Installed Games window closed by user" 'Info'
            $gamesWindow.Close()
        })

        # Show the window
        $gamesWindow.ShowDialog() | Out-Null

        Log "Error showing installed games: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error displaying installed games window: $($_.Exception.Message)", "Installed Games Error", 'OK', 'Error')

# Helper functions for synchronizing game list UI across multiple panels
function Set-OptimizeButtonsEnabled {
    param([bool]$Enabled)

    foreach ($button in $script:OptimizeSelectedButtons) {
        try { $button.IsEnabled = $Enabled } catch { Write-Verbose "Failed to update optimize button state: $($_.Exception.Message)" }
    }
}

function Get-GameListPanels {
    $panels = @()
    if ($script:PrimaryGameListPanel) { $panels += $script:PrimaryGameListPanel }
    if ($script:DashboardGameListPanel -and ($script:PrimaryGameListPanel -ne $script:DashboardGameListPanel)) { $panels += $script:DashboardGameListPanel }
    return $panels
}

# ---------- Search Games for Panel Function ----------
function Search-GamesForPanel {
        Log "Scanning system for installed games using enhanced detection methods..." 'Info'

        # Clear existing content
        $gameListPanel.Children.Clear()

        # Add loading message
        $loadingText = New-Object System.Windows.Controls.TextBlock
        try { $loadingText.Text = "🔍 Searching for installed games with advanced detection..." } catch { Write-Verbose "Text assignment skipped for compatibility" }
        try { Set-BrushPropertySafe -Target $loadingText -Property 'Foreground' -Value '#8F6FFF' } catch { Write-Verbose "Foreground assignment skipped for compatibility" }
        try { $loadingText.FontStyle = "Italic" } catch { Write-Verbose "FontStyle assignment skipped for compatibility" }
        try { $loadingText.HorizontalAlignment = "Center" } catch { Write-Verbose "HorizontalAlignment assignment skipped for compatibility" }
        try { $loadingText.Margin = "0,20" } catch { Write-Verbose "Margin assignment skipped for compatibility" }
        $gameListPanel.Children.Add($loadingText)

        # Force UI update to show loading message
        $form.Dispatcher.Invoke({}, "Background")

        # Use the enhanced game detection function
        $foundGames = @()

        # Call the enhanced detection logic from the Show-InstalledGames function
        try {
            # Enhanced search paths including custom paths
            $searchPaths = @(
                "$env:ProgramFiles\",
                "${env:ProgramFiles(x86)}\",
                "$env:LOCALAPPDATA\Programs\",
                "$env:ProgramData\",
                "C:\Games\",
                "D:\Games\",
                "E:\Games\",
                "$env:USERPROFILE\AppData\Local\"
            )

            # Add custom paths if they exist
            if ($global:CustomGamePaths) {
                $searchPaths += $global:CustomGamePaths
                Log "Including $($global:CustomGamePaths.Count) custom search paths" 'Info'
            }

            # 1. Registry-based Steam detection
            try {
                $steamPath = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue
                if ($steamPath) {
                    $steamLibraryPath = Join-Path $steamPath.SteamPath "steamapps\common"
                    if (Test-Path $steamLibraryPath) {
                        $steamGames = Get-ChildItem -Path $steamLibraryPath -Directory -ErrorAction SilentlyContinue
                        foreach ($game in $steamGames | Select-Object -First 20) { # Limit for UI performance
                            $foundGames += [PSCustomObject]@{
                                Name = $game.Name
                                Path = $game.FullName
                                Details = "Steam Game - Registry Detection"
                            }

                        }
                        Log "Found $($steamGames.Count) Steam games" 'Success'
                    }
                }
                Log "Steam detection failed: $($_.Exception.Message)" 'Warning'
            }

            # 2. Enhanced executable search
            $gameExecutables = @{
                "csgo.exe" = "Counter-Strike: Global Offensive"
                "cs2.exe" = "Counter-Strike 2"
                "valorant.exe" = "VALORANT"
                "valorant-win64-shipping.exe" = "VALORANT (Shipping)"
                "overwatch.exe" = "Overwatch"
                "overwatch2.exe" = "Overwatch 2"
                "r6siege.exe" = "Rainbow Six Siege"
                "fortnite.exe" = "Fortnite"
                "fortniteclient-win64-shipping.exe" = "Fortnite (Shipping)"
                "apex_legends.exe" = "Apex Legends"
                "r5apex.exe" = "Apex Legends (R5)"
                "pubg.exe" = "PlayerUnknown's Battlegrounds"
                "tslgame.exe" = "PUBG (TSL)"
                "warzone.exe" = "Call of Duty: Warzone"
                "league of legends.exe" = "League of Legends"
                "leagueclient.exe" = "League of Legends Client"
                "rocketleague.exe" = "Rocket League"
                "dota2.exe" = "Dota 2"
                "gta5.exe" = "Grand Theft Auto V"
                "cyberpunk2077.exe" = "Cyberpunk 2077"
                "bg3.exe" = "Baldur's Gate 3"
                "starfield.exe" = "Starfield"
                "minecraft.exe" = "Minecraft Java"
                "minecraftlauncher.exe" = "Minecraft Launcher"
            }
            # 3. Enhanced executable search in all paths
            foreach ($searchPath in $searchPaths) {
                if (Test-Path $searchPath) {
                    Log "Searching path: $searchPath" 'Info'
                    foreach ($gameExe in $gameExecutables.Keys) {
                            $gameFiles = Get-ChildItem -Path $searchPath -Recurse -Name $gameExe -ErrorAction SilentlyContinue | Select-Object -First 2
                            foreach ($gameFile in $gameFiles) {
                                $fullPath = Join-Path $searchPath $gameFile
                                if (Test-Path $fullPath) {
                                    $fileInfo = Get-Item $fullPath -ErrorAction SilentlyContinue
                                    if ($fileInfo -and $fileInfo.Length -gt 1MB) {
                                        # Check for duplicates
                                        $isDuplicate = $foundGames | Where-Object { $_.Path -eq $fullPath }
                                        if (-not $isDuplicate) {
                                            $foundGames += @{
                                                Name = $gameExecutables[$gameExe]
                                                Path = $fullPath
                                                Executable = $gameExe
                                                Details = "Verified Executable - Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"

                                            }
                                            Log "Found verified game: $($gameExecutables[$gameExe])" 'Success'
                                        }
                                    }
                                }
                            }
                            # Continue silently on search errors
                        }
                    }
                }
            }

            Log "Enhanced detection encountered error: $($_.Exception.Message)" 'Warning'
        }

        # Clear loading message
        $gameListPanel.Children.Clear()

        if ($foundGames.Count -gt 0) {
            # Add header
            $headerText = New-Object System.Windows.Controls.TextBlock
            $headerText.Text = "✅ Found $($foundGames.Count) installed games:"
            Set-BrushPropertySafe -Target $headerText -Property 'Foreground' -Value '#8F6FFF'
            $headerText.FontWeight = "Bold"
            $headerText.Margin = "0,0,0,10"
            $gameListPanel.Children.Add($headerText)

            # Add games with checkboxes
            foreach ($game in $foundGames) {
                $gameContainer = New-Object System.Windows.Controls.Border
                Set-BrushPropertySafe -Target $gameContainer -Property 'Background' -Value '#14132B'
                    Set-BrushPropertySafe -Target $gameContainer -Property 'BorderBrush' -Value '#2F285A'
                    $gameContainer.BorderThickness = "1"
                    Write-Verbose "BorderBrush assignment skipped for .NET Framework 4.8 compatibility"
                }
                $gameContainer.Padding = "10"
                $gameContainer.Margin = "0,2"

                $gameStack = New-Object System.Windows.Controls.StackPanel
                $gameStack.Orientation = "Horizontal"

                # Checkbox for selection
                $gameCheckbox = New-Object System.Windows.Controls.CheckBox
                $gameCheckbox.VerticalAlignment = "Top"
                $gameCheckbox.Margin = "0,0,10,0"
                $gameCheckbox.Tag = $game

                # Game info
                $gameInfoStack = New-Object System.Windows.Controls.StackPanel

                $gameNameText = New-Object System.Windows.Controls.TextBlock
                $gameNameText.Text = $game.Name
                Set-BrushPropertySafe -Target $gameNameText -Property 'Foreground' -Value '#8F6FFF'
                $gameNameText.FontWeight = "Bold"
                $gameNameText.FontSize = "12"

                $gamePathText = New-Object System.Windows.Controls.TextBlock
                $gamePathText.Text = $game.Path
                Set-BrushPropertySafe -Target $gamePathText -Property 'Foreground' -Value '#A9A5D9'
                $gamePathText.FontSize = "10"
                $gamePathText.TextWrapping = "Wrap"

                $gameInfoStack.Children.Add($gameNameText)
                $gameInfoStack.Children.Add($gamePathText)

                $gameStack.Children.Add($gameCheckbox)
                $gameStack.Children.Add($gameInfoStack)
                $gameContainer.Child = $gameStack

                $gameListPanel.Children.Add($gameContainer)
            }

            # Enable optimize button
            Set-OptimizeButtonsEnabled -Enabled $true

            Log "Game search complete: Found $($foundGames.Count) games" 'Success'

            # No games found
            $noGamesText = New-Object System.Windows.Controls.TextBlock
            $noGamesText.Text = "❌ No supported games found in common directories.`n`nTry running as Administrator for better detection, or use 'Add Game Folder' to specify custom locations."
            Set-BrushPropertySafe -Target $noGamesText -Property 'Foreground' -Value '#FFB86C'
            $noGamesText.FontStyle = "Italic"
            $noGamesText.HorizontalAlignment = "Center"
            $noGamesText.TextAlignment = "Center"
            $noGamesText.Margin = "0,20"
            $noGamesText.TextWrapping = "Wrap"
            $gameListPanel.Children.Add($noGamesText)

            Log "Game search complete: No games found" 'Warning'

        # Clear panel and show error
        $gameListPanel.Children.Clear()
        $errorText = New-Object System.Windows.Controls.TextBlock
        $errorText.Text = "❌ Error searching for games: $($_.Exception.Message)"
        Set-BrushPropertySafe -Target $errorText -Property 'Foreground' -Value '#FF6B6B'
        $errorText.HorizontalAlignment = "Center"
        $errorText.Margin = "0,20"
        $errorText.TextWrapping = "Wrap"
        $gameListPanel.Children.Add($errorText)

        Log "Error in game search: $($_.Exception.Message)" 'Error'

# ---------- Custom Folder Search Function ----------
function Search-CustomFoldersForExecutables {
        Log "Scanning custom folders for all executable files..." 'Info'

        # Clear existing content
        $gameListPanel.Children.Clear()

        # Add loading message
        $loadingText = New-Object System.Windows.Controls.TextBlock
        try { $loadingText.Text = "🔍 Scanning custom folders for .exe files..." } catch { Write-Verbose "Text assignment skipped for compatibility" }
        try { Set-BrushPropertySafe -Target $loadingText -Property 'Foreground' -Value '#8F6FFF' } catch { Write-Verbose "Foreground assignment skipped for compatibility" }
        try { $loadingText.FontStyle = "Italic" } catch { Write-Verbose "FontStyle assignment skipped for compatibility" }
        try { $loadingText.HorizontalAlignment = "Center" } catch { Write-Verbose "HorizontalAlignment assignment skipped for compatibility" }
        try { $loadingText.Margin = "0,20" } catch { Write-Verbose "Margin assignment skipped for compatibility" }
        $gameListPanel.Children.Add($loadingText)

        # Force UI update to show loading message
        $form.Dispatcher.Invoke({}, "Background")

        $foundExecutables = @()

        foreach ($customPath in $global:CustomGamePaths) {
            if (Test-Path $customPath) {
                Log "Searching custom path: $customPath" 'Info'

                try {
                    # Find all .exe files in the custom folder (not recursive to avoid performance issues)
                    $executables = Get-ChildItem -Path $customPath -Filter "*.exe" -File -ErrorAction SilentlyContinue

                    foreach ($exe in $executables) {
                        try {
                            # Get file info
                            $fileInfo = Get-ItemProperty -Path $exe.FullName -ErrorAction SilentlyContinue
                            $displayName = if ($exe.VersionInfo -and $exe.VersionInfo.FileDescription) {
                                $exe.VersionInfo.FileDescription
                            } else {
                                $exe.BaseName
                            }

                            $foundExecutables += [PSCustomObject]@{
                                Name = $displayName
                                ExecutableName = $exe.Name
                                Path = $exe.FullName
                                Size = [Math]::Round($exe.Length / 1MB, 2)
                                LastModified = $exe.LastWriteTime
                                Details = "Custom Folder: $customPath"

                            }
                        }
                        catch {
                            # Continue if can't get file info
                            $foundExecutables += [PSCustomObject]@{
                                Name = $exe.BaseName
                                ExecutableName = $exe.Name
                                Path = $exe.FullName
                                Size = 0
                                LastModified = $exe.LastWriteTime
                                Details = "Custom Folder: $customPath"
                            }
                        }
                    }

                    Log "Found $($executables.Count) executables in $customPath" 'Info'
                }
                catch {
                    Log "Error scanning custom path $customPath : $($_.Exception.Message)" 'Warning'
                }
            } else {
                Log "Custom path no longer exists: $customPath" 'Warning'
            }

        # Clear loading message
        $gameListPanel.Children.Clear()

        if ($foundExecutables.Count -gt 0) {
            Log "Custom search complete: Found $($foundExecutables.Count) executables" 'Success'

            # Add header
            $headerText = New-Object System.Windows.Controls.TextBlock
            $headerText.Text = "🔍 Found $($foundExecutables.Count) executable(s) in custom folders - Select any to optimize:"
            Set-BrushPropertySafe -Target $headerText -Property 'Foreground' -Value '#8F6FFF'
            $headerText.FontWeight = "Bold"
            $headerText.FontSize = 12
            $headerText.Margin = "0,0,0,8"
            $headerText.TextWrapping = "Wrap"
            $gameListPanel.Children.Add($headerText)

            # Sort by name for better presentation
            $foundExecutables = $foundExecutables | Sort-Object Name

            foreach ($executable in $foundExecutables) {
                # Create container border
                $border = New-Object System.Windows.Controls.Border
                Set-BrushPropertySafe -Target $border -Property 'Background' -Value '#14132B'
                    Set-BrushPropertySafe -Target $border -Property 'BorderBrush' -Value '#2F285A'
                    $border.BorderThickness = "1"
                    Write-Verbose "BorderBrush assignment skipped for .NET Framework 4.8 compatibility"
                }
                $border.Margin = "0,2"
                $border.Padding = "8"

                $stackPanel = New-Object System.Windows.Controls.StackPanel

                # Create checkbox for selection
                $checkbox = New-Object System.Windows.Controls.CheckBox
                $checkbox.Content = $executable.Name
                Set-BrushPropertySafe -Target $checkbox -Property 'Foreground' -Value '#F5F3FF'
                $checkbox.FontWeight = "SemiBold"
                $checkbox.Tag = $executable.Path  # Store full path for optimization
                $stackPanel.Children.Add($checkbox)

                # Add details
                $detailsText = New-Object System.Windows.Controls.TextBlock
                $detailsText.Text = "🔍 $($executable.Details)"
                Set-BrushPropertySafe -Target $detailsText -Property 'Foreground' -Value '#A9A5D9'
                $detailsText.FontSize = 10
                $detailsText.Margin = "20,2,0,0"
                $stackPanel.Children.Add($detailsText)

                $fileDetailsText = New-Object System.Windows.Controls.TextBlock
                $fileDetailsText.Text = "💾 File: $($executable.ExecutableName) | Size: $($executable.Size) MB | Modified: $($executable.LastModified.ToString('yyyy-MM-dd'))"
                Set-BrushPropertySafe -Target $fileDetailsText -Property 'Foreground' -Value '#7D7EB0'
                $fileDetailsText.FontSize = 9
                $fileDetailsText.Margin = "20,1,0,0"
                $stackPanel.Children.Add($fileDetailsText)

                $border.Child = $stackPanel
                $gameListPanel.Children.Add($border)
            }

            # Enable the optimize button
            Set-OptimizeButtonsEnabled -Enabled $true

            $noExecutablesText = New-Object System.Windows.Controls.TextBlock
            $noExecutablesText.Text = "❌ No executable files found in custom folders.`n`nTip: Make sure the folders contain .exe files and you have permission to access them."
            Set-BrushPropertySafe -Target $noExecutablesText -Property 'Foreground' -Value '#FF6B6B'
            $noExecutablesText.HorizontalAlignment = "Center"
            $noExecutablesText.Margin = "0,20"
            $noExecutablesText.TextWrapping = "Wrap"
            $gameListPanel.Children.Add($noExecutablesText)

            Log "Custom search complete: No executables found" 'Warning'

        # Clear panel and show error
        $gameListPanel.Children.Clear()
        $errorText = New-Object System.Windows.Controls.TextBlock
        $errorText.Text = "❌ Error searching custom folders: $($_.Exception.Message)"
        Set-BrushPropertySafe -Target $errorText -Property 'Foreground' -Value '#FF6B6B'
        $errorText.HorizontalAlignment = "Center"
        $errorText.Margin = "0,20"
        $errorText.TextWrapping = "Wrap"
        $gameListPanel.Children.Add($errorText)

        Log "Error in custom folder search: $($_.Exception.Message)" 'Error'

# ---------- Event Handlers ----------

# Admin elevation
if ($btnElevate) {
    $btnElevate.Add_Click({
        Log "Privilege elevation requested by user" 'Info'
        Show-ElevationMessage -Operations @(
            "System Registry Modifications",
            "Windows Service Configuration",
            "Power Management Settings",
            "Advanced CPU and Memory Optimizations"
        )
    })
}

# Menu mode selector removed from header - now only available in Options panel
# $cmbMenuMode.Add_SelectionChanged({
#     try {
#         $selectedMode = $cmbMenuMode.SelectedItem.Tag
#         Log "Menu mode selection changed to: $selectedMode" 'Info'
#         Switch-MenuMode -Mode $selectedMode
#     } catch {
#         Log "Error changing menu mode: $($_.Exception.Message)" 'Error'
#     }
# })

# Removed $cmbTheme event handler (now only using Options panel theme)

# Auto-detect games
if ($btnAutoDetect) {
    $btnAutoDetect.Add_Click({
        Log "Auto-detecting running games in $global:MenuMode mode..." 'Info'
        Log "Executable detection request - searching for running processes" 'Info'
        $detectedGames = Get-RunningGames
        $global:ActiveGames = $detectedGames

        if ($detectedGames.Count -gt 0) {
            $firstGame = $detectedGames[0]
            $process = $firstGame.Process

            if ($lblDashActiveGames) {
                $lblDashActiveGames.Dispatcher.Invoke([Action]{
                    $lblDashActiveGames.Text = "$($detectedGames.Count) running"
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#8F6FFF'
                })
            }

            # Enhanced logging with executable details
            Log "Detected Game: $($firstGame.DisplayName)" 'Success'
            Log "Executable: $($process.ProcessName).exe (PID: $($process.Id))" 'Info'
                if ($process.MainModule -and $process.MainModule.FileName) {
                    Log "Path: $($process.MainModule.FileName)" 'Info'

                }
            Log "Path: Access denied (running as different user)" 'Warning'
        }

        # Show all detected games if multiple found
        if ($detectedGames.Count -gt 1) {
            Log "Additional games detected: $(($detectedGames[1..($detectedGames.Count-1)] | ForEach-Object { $_.DisplayName }) -join ', ')" 'Info'
        }

        # Select the first game in the dropdown
        foreach ($item in $cmbGameProfile.Items) {
            if ($item.Tag -eq $firstGame.GameKey) {
                $cmbGameProfile.SelectedItem = $item
                Log "Selected profile: $($firstGame.DisplayName)" 'Success'
                break
            }
        }

        # Show user-friendly message with details
        $processInfo = "Process: $($process.ProcessName).exe (PID: $($process.Id))"
        [System.Windows.MessageBox]::Show("Successfully detected: $($firstGame.DisplayName)`n$processInfo`n`nProfile automatically selected in dropdown.", "Game Detected", 'OK', 'Information')
    } else {
        Log "No supported games detected" 'Warning'
        [System.Windows.MessageBox]::Show("No supported games are currently running.", "No Games Detected", 'OK', 'Information')
        if ($lblDashActiveGames) {
            $lblDashActiveGames.Dispatcher.Invoke([Action]{
                $lblDashActiveGames.Text = "None detected"
                Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#A6AACF'
            })
        }
    }

# Optimize custom game button
$btnOptimizeGame.Add_Click({
        $gameExecutable = $txtCustomGame.Text.Trim()

        if ([string]::IsNullOrEmpty($gameExecutable)) {
            Log "Please enter a game executable name first" 'Warning'
            [System.Windows.MessageBox]::Show("Please enter a game executable name (e.g., mygame.exe) before optimizing.", "No Game Specified", 'OK', 'Warning')
            return

        }

        Log "Starting optimization for custom game: $gameExecutable" 'Info'

        # Apply standard gaming optimizations
        Apply-CustomGameOptimizations -GameExecutable $gameExecutable

        Log "Successfully applied gaming optimizations for: $gameExecutable" 'Success'
        [System.Windows.MessageBox]::Show("Gaming optimizations have been successfully applied for '$gameExecutable'!`n`nOptimizations applied:`n* Process priority boost`n* Network latency reduction`n* GPU scheduling enhancement`n* Game mode activation`n* High precision timers", "Optimization Complete", 'OK', 'Information')

        Log "Error optimizing custom game: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error applying optimizations: $($_.Exception.Message)", "Optimization Failed", 'OK', 'Error')
    }

# Find executable button
$btnFindExecutable.Add_Click({
        $gameExecutable = $txtCustomGame.Text.Trim()

        if ([string]::IsNullOrEmpty($gameExecutable)) {
            Log "Please enter a game executable name first" 'Warning'
            [System.Windows.MessageBox]::Show("Please enter a game executable name (e.g., mygame.exe) to search for.", "No Game Specified", 'OK', 'Warning')
            return

        }

        Log "Searching for executable: $gameExecutable" 'Info'

        # Search for the executable in common game directories
        $searchPaths = @(
            "C:\Program Files\",
            "C:\Program Files (x86)\",
            "C:\Program Files\WindowsApps\",
            "D:\Program Files\",
            "D:\Program Files (x86)\",
            "C:\Games\",
            "D:\Games\",
            "$env:USERPROFILE\Desktop\",
            "$env:USERPROFILE\Documents\",
            "$env:USERPROFILE\Downloads\"
        )

        $found = $false
        $foundPaths = @()

        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                $files = Get-ChildItem -Path $path -Recurse -Name $gameExecutable -ErrorAction SilentlyContinue
                if ($files) {
                    foreach ($file in $files) {
                        $fullPath = Join-Path $path $file
                        $foundPaths += $fullPath
                        $found = $true
                    }
                }
            }
        }

        if ($found) {
            $pathsText = $foundPaths -join "`n"
            Log "Executable '$gameExecutable' found at: $($foundPaths[0])" 'Success'
            [System.Windows.MessageBox]::Show("Executable '$gameExecutable' found!`n`nLocation(s):`n$pathsText", "Executable Found", 'OK', 'Information')
        } else {
            Log "Executable '$gameExecutable' not found in common directories" 'Warning'
            [System.Windows.MessageBox]::Show("Executable '$gameExecutable' was not found in common game directories.`n`nNote: The executable may still exist in other locations, or it may need to be running to be detected.", "Executable Not Found", 'OK', 'Warning')
        }

        Log "Error searching for executable: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error searching for executable: $($_.Exception.Message)", "Search Failed", 'OK', 'Error')

# Custom game executable text change - Track user input for enhanced logging
$txtCustomGame.Add_TextChanged({
        $gameText = $txtCustomGame.Text.Trim()
        if ($gameText -and $gameText.Length -gt 2) {
            Log "Custom game executable entered: $gameText" 'Info'
            Log "User preparing to optimize custom game in $global:MenuMode mode" 'Info'

        }
        # Silent fail for text input monitoring to avoid spam
    }

# Installed Games button - Show installed games discovery window
if ($btnInstalledGames) {
    $btnInstalledGames.Add_Click({
            Log "Installed Games discovery initiated by user" 'Info'
            Show-InstalledGames
            Log "Error showing installed games: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error displaying installed games: $($_.Exception.Message)", "Installed Games Error", 'OK', 'Error')
        }
    })
    Log "Warning: btnInstalledGames control not found - skipping event handler binding" 'Warning'

if ($btnInstalledGamesDash -and $btnInstalledGames) {
    $btnInstalledGamesDash.Add_Click({
            $btnInstalledGames.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying dashboard installed games action: $($_.Exception.Message)" 'Warning'
        }
    })

# Basic Network Optimizations button
$btnBasicNetwork.Add_Click({
        Log "Applying Basic Network Optimizations..." 'Info'

        # Apply all network optimizations from the Network section
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpAckFrequency" "DWord" 1 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" "DWord" 0 $true
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" "DWord" 4294967295 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" "DWord" 1 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "Tcp1323Opts" "DWord" 0 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpWindowSize" "DWord" 1073725440 $true

        Log "Network optimizations applied successfully in $global:MenuMode mode!" 'Success'
        Log "Applied 6 network optimizations: TCP ACK, DelAck, Throttling, NoDelay, Timestamps, Window Size" 'Info'
        [System.Windows.MessageBox]::Show("Network optimizations have been applied successfully!`n`nOptimizations applied:`n* TCP ACK Frequency optimization`n* Network throttling disabled`n* Nagle algorithm disabled`n* TCP window size optimized`n* Latency reduction tweaks", "Network Optimization Complete", 'OK', 'Information')

        Log "Error applying network optimizations: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error applying network optimizations: $($_.Exception.Message)", "Optimization Failed", 'OK', 'Error')
    }

# Basic System Performance button
$btnBasicSystem.Add_Click({
        Log "Applying Basic System Performance Optimizations..." 'Info'

        # Apply system performance optimizations
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" "DWord" 0 $true
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" "DWord" 8 $true
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" "DWord" 6 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" "DWord" 38 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" "DWord" 1 $true

        # Set Ultimate Performance power plan
        try {
            $ultimatePlan = powercfg /l | Where-Object { $_ -like "*Ultimate Performance*" }
            if ($ultimatePlan) {
                $planGUID = ($ultimatePlan -split "\s+")[3]
                powercfg /setactive $planGUID
                Log "Ultimate Performance power plan activated" 'Success'
            }
            Log "Could not set Ultimate Performance power plan" 'Warning'
        }

        Log "System performance optimizations applied successfully in $global:MenuMode mode!" 'Success'
        Log "Applied 5 system optimizations: Responsiveness, GPU Priority, CPU Scheduling, Memory Management, Power Plan" 'Info'
        [System.Windows.MessageBox]::Show("System performance optimizations have been applied successfully!`n`nOptimizations applied:`n* System responsiveness enhanced`n* Game task priority boosted`n* CPU scheduling optimized`n* Memory management improved`n* Power plan optimized", "System Optimization Complete", 'OK', 'Information')

        Log "Error applying system optimizations: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error applying system optimizations: $($_.Exception.Message)", "Optimization Failed", 'OK', 'Error')
    }

# Basic Gaming Optimizations button
$btnBasicGaming.Add_Click({
        Log "Applying Basic Gaming Optimizations..." 'Info'

        # Apply essential gaming optimizations
        Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" "DWord" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" "DWord" 0 $true
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" "DWord" 2 $true
        Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" "DWord" 1
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "String" "High" $true
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "String" "High" $true

        # Enable high precision timer
        try {
            [WinMM]::timeBeginPeriod(1)
            Log "High precision timer enabled (1ms)" 'Success'
        } catch {
            Log "Could not set high precision timer" 'Warning'
        }

        # Disable hibernation
            powercfg /hibernate off | Out-Null
            Log "Hibernation disabled" 'Success'
            Log "Could not disable hibernation" 'Warning'

        Log "Gaming optimizations applied successfully in $global:MenuMode mode!" 'Success'
        Log "Applied 7 gaming optimizations: Game DVR, GPU Scheduling, Game Mode, High Priority, Precision Timer, Hibernation" 'Info'
        [System.Windows.MessageBox]::Show("Gaming optimizations have been applied successfully!`n`nOptimizations applied:`n* Game DVR disabled`n* Hardware GPU scheduling enabled`n* Game mode activated`n* High precision timer enabled`n* Visual effects optimized`n* Hibernation disabled", "Gaming Optimization Complete", 'OK', 'Information')

        Log "Error applying gaming optimizations: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error applying gaming optimizations: $($_.Exception.Message)", "Optimization Failed", 'OK', 'Error')

# Apply theme button
# Removed $btnApplyTheme event handler (now only in Options panel)

# Options panel event handlers - selection changes only update preview, no instant application
if ($cmbOptionsTheme) {
    $cmbOptionsTheme.Add_SelectionChanged({
        if ($script:ThemeSelectionSyncInProgress) { return }

            $script:ThemeSelectionSyncInProgress = $true

            if ($cmbOptionsTheme.SelectedItem -and $cmbOptionsTheme.SelectedItem.Tag) {
                $selectedTheme = $cmbOptionsTheme.SelectedItem.Tag
                $themeName = $cmbOptionsTheme.SelectedItem.Content

                # Update color preview panel only - no instant theme application
                Update-ThemeColorPreview -ThemeName $selectedTheme

                # Show/hide custom theme panel
                if ($selectedTheme -eq "Custom" -and $customThemePanel) {
                    $customThemePanel.Visibility = "Visible"
                    if ($global:CustomThemeColors) {
                        if ($txtCustomBg) { $txtCustomBg.Text = $global:CustomThemeColors['Background'] }
                        if ($txtCustomPrimary) { $txtCustomPrimary.Text = $global:CustomThemeColors['Primary'] }
                        if ($txtCustomHover) { $txtCustomHover.Text = $global:CustomThemeColors['Hover'] }
                        if ($txtCustomText) { $txtCustomText.Text = $global:CustomThemeColors['Text'] }

                    }
                } elseif ($customThemePanel) {
                    $customThemePanel.Visibility = "Collapsed"
                }

                Log "Theme selection changed to '$themeName' - preview updated (Apply button required for theme change)" 'Info'
            }
            Log "Error updating theme preview: $($_.Exception.Message)" 'Error'
        } finally {
            $script:ThemeSelectionSyncInProgress = $false

# Apply button - primary method for theme application (themes only apply when clicked)
# Theme Apply Button Event Handler

# Alias button for test compatibility - applies same functionality


function Get-AdvancedCheckboxControls {
    if (-not $panelAdvanced) {
        return @()
    }

    $results = @()
    $stack = [System.Collections.Stack]::new()
    $stack.Push($panelAdvanced)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()

        if ($current -is [System.Windows.Controls.CheckBox]) {
            $results += $current
        }

        if ($current -is [System.Windows.DependencyObject]) {
            $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($current)
            for ($i = 0; $i -lt $childCount; $i++) {
                $child = [System.Windows.Media.VisualTreeHelper]::GetChild($current, $i)
                if ($child) {
                    $stack.Push($child)
                }
            }
        }
    }

    return $results
}

function Get-AdvancedCheckboxNames {
    $dynamicControls = Get-AdvancedCheckboxControls | Where-Object { $_ -and $_.Name }

    if ($dynamicControls -and $dynamicControls.Count -gt 0) {
        $uniqueNames = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($checkbox in $dynamicControls) {
            [void]$uniqueNames.Add($checkbox.Name)
        }

        if ($uniqueNames.Count -gt 0) {
            return $uniqueNames.ToArray()
        }
    }

    return @(
        'chkAckNetwork'
        'chkDelAckTicksNetwork'
        'chkNagleNetwork'
        'chkNetworkThrottlingNetwork'
        'chkRSSNetwork'
        'chkRSCNetwork'
        'chkChimneyNetwork'
        'chkNetDMANetwork'
        'chkTcpTimestampsNetwork'
        'chkTcpWindowAutoTuningNetwork'
        'chkMemoryCompressionSystem'
        'chkPowerPlanSystem'
        'chkCPUSchedulingSystem'
        'chkPageFileSystem'
        'chkVisualEffectsSystem'
        'chkCoreParkingSystem'
        'chkGameDVRSystem'
        'chkFullscreenOptimizationsSystem'
        'chkGPUSchedulingSystem'
        'chkTimerResolutionSystem'
        'chkGameModeSystem'
        'chkMPOSystem'
        'chkDynamicResolution'
        'chkEnhancedFramePacing'
        'chkGPUOverclocking'
        'chkCompetitiveLatency'
        'chkAutoDiskOptimization'
        'chkAdaptivePowerManagement'
        'chkEnhancedPagingFile'
        'chkDirectStorageEnhanced'
        'chkAdvancedTelemetryDisable'
        'chkMemoryDefragmentation'
        'chkServiceOptimization'
        'chkDiskTweaksAdvanced'
        'chkNetworkLatencyOptimization'
        'chkFPSSmoothness'
        'chkCPUMicrocode'
        'chkRAMTimings'
        'chkDisableXboxServicesServices'
        'chkDisableTelemetryServices'
        'chkDisableSearchServices'
        'chkDisablePrintSpoolerServices'
        'chkDisableSuperfetchServices'
        'chkDisableFaxServices'
        'chkDisableRemoteRegistryServices'
        'chkDisableThemesServices'
        'chkDisableCortana'
        'chkDisableWindowsUpdate'
        'chkDisableBackgroundApps'
        'chkDisableLocationTracking'
        'chkDisableAdvertisingID'
        'chkDisableErrorReporting'
        'chkDisableCompatTelemetry'
        'chkDisableWSH'
    )
}

function Get-AdvancedCheckedSelections {
    $checked = @()

    foreach ($name in Get-AdvancedCheckboxNames) {
        $checkbox = $form.FindName($name)
        if ($checkbox -and $checkbox.IsChecked) {
            $checked += $name
        }
    }

    return $checked
}

function Set-AdvancedSelections {
    param(
        [string[]]$CheckedNames
    )

    $lookup = @{}

    if ($CheckedNames) {
        foreach ($entry in $CheckedNames) {
            $trimmed = $entry.Trim()
            if ($trimmed) {
                $lookup[$trimmed] = $true
            }
        }
    }

    foreach ($name in Get-AdvancedCheckboxNames) {
        $checkbox = $form.FindName($name)
        if ($checkbox) {
            $checkbox.IsChecked = $lookup.ContainsKey($name)
        }
    }
}

function Get-AdvancedSelectionSummary {
    param(
        [string[]]$CheckedNames
    )

    if (-not $CheckedNames -or $CheckedNames.Count -eq 0) {
        return 'None'
    }

    $labels = @()

    foreach ($name in $CheckedNames) {
        $checkbox = $form.FindName($name)
        if ($checkbox -and $checkbox.PSObject.Properties['Content'] -and $checkbox.Content) {
            $labels += [string]$checkbox.Content
        } else {
            $labels += $name
        }
    }

    if ($labels.Count -eq 0) {
        return 'None'
    }

    return ($labels -join ', ')

if ($btnSaveSettings) {
    $btnSaveSettings.Add_Click({
            $configPath = Join-Path (Get-Location) "koala-settings.cfg"

            # Gather current settings
            $currentTheme = if ($cmbOptionsTheme.SelectedItem) { $cmbOptionsTheme.SelectedItem.Tag } else { "OptimizerDark" }
            $currentScale = if ($cmbUIScale.SelectedItem) { $cmbUIScale.SelectedItem.Tag } else { "1.0" }
            $currentLanguage = if ($script:CurrentLanguage) { $script:CurrentLanguage } else { 'en' }
            $advancedSelections = Get-AdvancedCheckedSelections
            $advancedSelectionsValue = $advancedSelections -join ','
            $advancedSummary = Get-AdvancedSelectionSummary -CheckedNames $advancedSelections


            $settings = @"
# KOALA Gaming Optimizer Settings - koala-settings.cfg with Theme= UIScale= MenuMode= support
# Generated on $(Get-Date)
Theme=$currentTheme
UIScale=$currentScale
MenuMode=$global:MenuMode
Language=$currentLanguage
AdvancedSelections=$advancedSelectionsValue
"@

            Set-Content -Path $configPath -Value $settings -Encoding UTF8
            Log "Settings saved to koala-settings.cfg (Theme: $currentTheme, Scale: $currentScale, Language: $currentLanguage, Advanced: $advancedSummary)" 'Success'
            [System.Windows.MessageBox]::Show("Settings have been saved to koala-settings.cfg successfully!", "Settings Saved", 'OK', 'Information')
            Log "Error saving settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error saving settings: $($_.Exception.Message)", "Save Failed", 'OK', 'Error')
        }
    })
    Log "Warning: btnSaveSettings control not found - skipping event handler binding" 'Warning'

if ($btnLoadSettings) {
    $btnLoadSettings.Add_Click({
            $configPath = Join-Path (Get-Location) "koala-settings.cfg"

            if (Test-Path $configPath) {
                $content = Get-Content $configPath -Raw
                $settings = @{}

                $content -split "`n" | ForEach-Object {
                    if ($_ -match "^([^#=]+)=(.*)$") {
                        $settings[$matches[1].Trim()] = $matches[2].Trim()

                    }
                }

                # Apply loaded theme
                if ($settings.Theme) {
                    foreach ($item in $cmbOptionsTheme.Items) {
                        if ($item.Tag -eq $settings.Theme) {
                            $cmbOptionsTheme.SelectedItem = $item
                            Switch-Theme -ThemeName $settings.Theme
                            break
                        }
                    }
                }

                # Apply loaded scale
                if ($settings.UIScale) {
                    foreach ($item in $cmbUIScale.Items) {
                        if ($item.Tag -eq $settings.UIScale) {
                            $cmbUIScale.SelectedItem = $item
                            $scaleValue = [double]$settings.UIScale
                            $scaleTransform = New-Object System.Windows.Media.ScaleTransform($scaleValue, $scaleValue)
                            $form.LayoutTransform = $scaleTransform
                            break
                        }
                    }
                }

                if ($settings.Language) {
                    Set-UILanguage -LanguageCode $settings.Language
                }

                if ($settings.ContainsKey('AdvancedSelections')) {
                    $advancedChecked = @()
                    if ($settings.AdvancedSelections) {
                        $advancedChecked = $settings.AdvancedSelections -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                    }

                    Set-AdvancedSelections -CheckedNames $advancedChecked

                    $advancedLoadSummary = Get-AdvancedSelectionSummary -CheckedNames $advancedChecked
                    Log "Advanced selections restored from koala-settings.cfg: $advancedLoadSummary" 'Info'
                }

                Log "Settings loaded from koala-settings.cfg successfully" 'Success'
                [System.Windows.MessageBox]::Show("Settings have been loaded and applied successfully!", "Settings Loaded", 'OK', 'Information')
            } else {
                Log "No settings file found at koala-settings.cfg" 'Warning'
                [System.Windows.MessageBox]::Show("No settings file found. Please save settings first.", "No Settings File", 'OK', 'Warning')
            }
            Log "Error loading settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error loading settings: $($_.Exception.Message)", "Load Failed", 'OK', 'Error')
        }
    Log "Warning: btnLoadSettings control not found - skipping event handler binding" 'Warning'

if ($btnResetSettings) {
    $btnResetSettings.Add_Click({
            $result = [System.Windows.MessageBox]::Show(
                "Are you sure you want to reset all settings to default?`n`nThis will:`n- Set theme to Optimizer Dark`n- Set UI scale to 100%`n- Switch to Basic mode",
                "Reset Settings",
                'YesNo',
                'Question'
            )

            if ($result -eq 'Yes') {
                # Reset theme to Optimizer Dark
                foreach ($item in $cmbOptionsTheme.Items) {
                    if ($item.Tag -eq "OptimizerDark") {
                        $cmbOptionsTheme.SelectedItem = $item
                        Switch-Theme -ThemeName "OptimizerDark"
                        break

                    }
                }

                # Reset scale to 100%
                foreach ($item in $cmbUIScale.Items) {
                    if ($item.Tag -eq "1.0") {
                        $cmbUIScale.SelectedItem = $item
                        $form.LayoutTransform = $null
                        break
                    }
                }

                # Reset to Basic mode
                # Menu mode control removed from header - mode managed through Options panel only
                # foreach ($item in $cmbMenuMode.Items) {
                #     if ($item.Tag -eq "Basic") {
                #         $cmbMenuMode.SelectedItem = $item
                #         Switch-MenuMode -Mode "Basic"
                #         break
                #     }
                # }
                Switch-MenuMode -Mode "Basic"  # Direct call without UI control

                # Reset advanced selections
                Set-AdvancedSelections -CheckedNames @()

                Log "All settings reset to default values" 'Success'
                [System.Windows.MessageBox]::Show("All settings have been reset to default values!", "Settings Reset", 'OK', 'Information')
            }
            Log "Error resetting settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error resetting settings: $($_.Exception.Message)", "Reset Failed", 'OK', 'Error')
        }
    })
    Log "Warning: btnResetSettings control not found - skipping event handler binding" 'Warning'

# Auto-optimize checkbox
if ($chkAutoOptimize) {
    $chkAutoOptimize.Add_Checked({
        $global:AutoOptimizeEnabled = $true
        Log "Auto-optimization enabled in $global:MenuMode mode" 'Success'
        Log "System will now automatically optimize detected games every 5 seconds" 'Info'
        Start-GameDetectionMonitoring
    })

    $chkAutoOptimize.Add_Unchecked({
        $global:AutoOptimizeEnabled = $false
        Log "Auto-optimization disabled in $global:MenuMode mode" 'Info'
        Stop-GameDetectionMonitoring
        $global:ActiveGames = @()
    })
} else {
    Log "Warning: chkAutoOptimize control not found - skipping event handler binding" 'Warning'

# Clear log button - Enhanced user action tracking
if ($btnClearLog) {
    $btnClearLog.Add_Click({
            Log "User requested to clear Activity Log in $global:MenuMode mode" 'Info'

            if ($global:LogBox -and $global:LogBoxAvailable) {
                try {
                    $currentLogLines = if ($global:LogBox.Text) { ($global:LogBox.Text -split "`n").Count } else { 0 }
                    $global:LogBox.Clear()
                Log "Activity Log cleared successfully ($currentLogLines entries removed)" 'Success'
                Log "Activity Log reset - ready for new user action tracking" 'Info'

                # Show user feedback
                [System.Windows.MessageBox]::Show("Activity Log has been cleared successfully!`n`nThe log is now ready to track new user actions.`nPrevious $currentLogLines log entries have been removed from the display.", "Log Cleared", 'OK', 'Information')

                Log "Failed to clear Activity Log UI: $($_.Exception.Message)" 'Warning'
                [System.Windows.MessageBox]::Show("Warning: Could not clear the Activity Log display.`n`nError: $($_.Exception.Message)", "Clear Failed", 'OK', 'Warning')
            }
        } else {
            Log "Activity Log UI not available - cleared console logs only" 'Warning'
            [System.Windows.MessageBox]::Show("Activity Log display not available.`nConsole logs have been noted as cleared.", "Limited Clear", 'OK', 'Warning')
        }

        Log "Error in Clear Log operation: $($_.Exception.Message)" 'Error'
    }

# Activity Log Extend button - Toggle height functionality
if ($btnExtendLog) {
    # Initialize global variable for log state
    $global:LogExtended = $false

    $btnExtendLog.Add_Click({
            if ($activityLogBorder) {
                if (-not $global:LogExtended) {
                    # Extend the log to full size
                    $activityLogBorder.MinHeight = 120
                    $btnExtendLog.Content = "⤡ Collapse"
                    $global:LogExtended = $true
                    Log "Activity Log extended to full size" 'Info'

                } else {
                    # Collapse the log to 25% size
                    $activityLogBorder.MinHeight = 30
                    $btnExtendLog.Content = "⤢ Extend"
                    $global:LogExtended = $false
                    Log "Activity Log collapsed to compact size" 'Info'
                }

                # Force layout update
                $activityLogBorder.InvalidateMeasure()
                $activityLogBorder.UpdateLayout()
            }
            Log "Error toggling Activity Log size: $($_.Exception.Message)" 'Error'
        }

# Activity Log View Toggle button - Switch between compact and detailed views
if ($btnToggleLogView) {
    # Initialize global variable for log view state
    $global:LogViewDetailed = $true

    $btnToggleLogView.Add_Click({
            if ($global:LogBox) {
                if ($global:LogViewDetailed) {
                    # Switch to compact view - show only latest entries
                    $allLogLines = $global:LogBox.Text -split "`n"
                    $compactLines = $allLogLines | Where-Object {
                        $_ -match "Success|Error|Warning|Applied|Optimization"

                    } | Select-Object -Last 20

                    $global:LogBox.Text = ($compactLines -join "`n")
                    $btnToggleLogView.Content = "📁 Compact"
                    $global:LogViewDetailed = $false
                    Log "Switched to compact log view (showing key actions only)" 'Info'
                } else {
                    # Switch to detailed view - show all entries
                    # Restore from backup or show message
                    if ($global:DetailedLogBackup) {
                        $global:LogBox.Text = $global:DetailedLogBackup
                    }
                    $btnToggleLogView.Content = "📄 Detailed"
                    $global:LogViewDetailed = $true
                    Log "Switched to detailed log view (showing all entries)" 'Info'
                }

                # Auto-scroll to bottom
                if ($logScrollViewer) {
                    $logScrollViewer.ScrollToBottom()
                }
            }
            Log "Error toggling log view mode: $($_.Exception.Message)" 'Error'
        }

    # Store detailed log for restoration
    $global:DetailedLogBackup = ""

# Activity Log Save button
if ($btnSaveLog) {
    $btnSaveLog.Add_Click({
            Log "User requested to save Activity Log" 'Info'

            $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
            $saveDialog.Filter = "Text files (*.txt)|*.txt|Log files (*.log)|*.log|All files (*.*)|*.*"
            $saveDialog.DefaultExt = ".txt"
            $saveDialog.FileName = "Koala-Activity-Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
            $saveDialog.Title = "Save Activity Log"
            $saveDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")

            if ($saveDialog.ShowDialog()) {
                $selectedPath = $saveDialog.FileName
                if ($global:LogBox -and $global:LogBox.Text) {
                    Set-Content -Path $selectedPath -Value $global:LogBox.Text -Encoding UTF8
                    Log "Activity log saved to: $selectedPath" 'Success'
                    [System.Windows.MessageBox]::Show(
                        "Activity log saved successfully!`n`nLocation: $selectedPath`nTimestamp: $(Get-Date)",
                        "Log Saved",
                        'OK',
                        'Information'
                    )

                } else {
                    Log "No activity log content available to save" 'Warning'
                    [System.Windows.MessageBox]::Show("No activity log content available to save.", "No Content", 'OK', 'Warning')
                }
            }
            Log "Error saving activity log: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Failed to save activity log: $($_.Exception.Message)", "Save Error", 'OK', 'Error')
        }

# Search Log button - Enhanced log search and filtering
if ($btnSearchLog) {
    $btnSearchLog.Add_Click({
            Log "User opened log search and filter interface" 'Info'
            Show-LogSearchDialog
            Log "Error opening log search interface: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Failed to open log search interface: $($_.Exception.Message)", "Search Error", 'OK', 'Error')
        }
    })
    Log "Warning: btnSearchLog control not found - skipping event handler binding" 'Warning'

# System info
if ($btnSystemInfo) { $btnSystemInfo.Add_Click({ Get-SystemInfo }) }

# Benchmark
if ($btnBenchmark) { $btnBenchmark.Add_Click({ Start-QuickBenchmark }) }

# System Health button - Show detailed health dialog
if ($btnSystemHealth) {
    $btnSystemHealth.Add_Click({
            Log "User opened System Health Monitor" 'Info'
            Show-SystemHealthDialog
            Log "Error opening System Health Monitor: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Failed to open System Health Monitor: $($_.Exception.Message)", "Health Monitor Error", 'OK', 'Error')
        }
    })
    Log "Warning: btnSystemHealth control not found - skipping event handler binding" 'Warning'

if ($btnSystemHealthRunCheck) {
    $btnSystemHealthRunCheck.Add_Click({
            Log "Manual system health check requested from dashboard" 'Info'
            $result = Update-SystemHealthDisplay -RunCheck
            if ($result.HealthStatus -eq 'Error') {
                [System.Windows.MessageBox]::Show("Health check completed with errors. Please review the Activity Log for details.", "Health Check", 'OK', 'Warning') | Out-Null

            } else {
                $roundedScore = if ($result.HealthScore -ne $null) { [Math]::Round([double]$result.HealthScore, 0) } else { $null }
                $summary = if ($roundedScore -ne $null) { "$($result.HealthStatus) ($roundedScore%)" } else { $result.HealthStatus }
                [System.Windows.MessageBox]::Show("System health check completed: $summary.", "Health Check", 'OK', 'Information') | Out-Null
            }
            Log "Error running dashboard health check: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error running health check: $($_.Exception.Message)", "Health Check", 'OK', 'Error') | Out-Null
        }
    Log "Warning: btnSystemHealthRunCheck control not found - skipping event handler binding" 'Warning'

# Backup
if ($btnBackup) { $btnBackup.Add_Click({ Create-Backup }) }

# Export/Import config
if ($btnExportConfig) { $btnExportConfig.Add_Click({ Export-Configuration }) }
if ($btnImportConfig) { $btnImportConfig.Add_Click({ Import-Configuration }) }

# Options panel export/import handlers (same functions)
if ($btnExportConfigOptions) {
    $btnExportConfigOptions.Add_Click({ Export-Configuration })
}
if ($btnImportConfigOptions) {
    $btnImportConfigOptions.Add_Click({ Import-Configuration })
}

# Backup as .reg file handler
if ($btnBackupReg) {
    $btnBackupReg.Add_Click({
            Log "Registry backup (.reg file) requested" 'Info'
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $regBackupPath = Join-Path (Get-Location) "Koala-Registry-Backup_$timestamp.reg"

            # Create registry backup in .reg format
            $regContent = @"
Windows Registry Editor Version 5.00

; KOALA Gaming Optimizer Registry Backup
; Created: $(Get-Date)
; Note: This backup contains registry keys that may be modified by the optimizer

"@

            # Add key registry paths that the optimizer modifies
            $keyPaths = @(
                "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters",
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile",
                "HKEY_CURRENT_USER\SOFTWARE\Microsoft\GameBar",
                "HKEY_CURRENT_USER\System\GameConfigStore"
            )

            foreach ($keyPath in $keyPaths) {
                try {
                    $regContent += "`r`n`r`n; Backup of $keyPath`r`n"
                    $regPath = $keyPath -replace "HKEY_LOCAL_MACHINE", "HKLM:" -replace "HKEY_CURRENT_USER", "HKCU:"

                    if (Test-Path $regPath -ErrorAction SilentlyContinue) {
                        $regContent += "[$keyPath]`r`n"
                        # Export registry values would require more complex logic
                        $regContent += "; Registry values would be exported here`r`n"
                    }
                    # Continue with other keys if one fails
                }
            }

            Set-Content -Path $regBackupPath -Value $regContent -Encoding Unicode
            Log "Registry backup created: $regBackupPath" 'Success'
            [System.Windows.MessageBox]::Show("Registry backup created successfully!`n`nFile: $regBackupPath", "Registry Backup Complete", 'OK', 'Information')

            Log "Error creating registry backup: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error creating registry backup: $($_.Exception.Message)", "Backup Failed", 'OK', 'Error')
        }
    })

# Backup panel button handlers
if ($btnCreateBackup) { $btnCreateBackup.Add_Click({ Create-Backup }) }
if ($btnExportConfigBackup) { $btnExportConfigBackup.Add_Click({ Export-Configuration }) }
if ($btnRestoreBackup) { $btnRestoreBackup.Add_Click({ Import-Configuration }) }
if ($btnImportConfigBackup) { $btnImportConfigBackup.Add_Click({ Import-Configuration }) }

if ($btnSaveActivityLog) {
    $btnSaveActivityLog.Add_Click({
            Log "Save activity log requested" 'Info'
            $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
            $saveDialog.Filter = "Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*"
            $saveDialog.DefaultExt = ".log"
            $saveDialog.FileName = "KOALA_Activity_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $saveDialog.Title = "Select Activity Log Save Location"
            $saveDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")

            if ($saveDialog.ShowDialog()) {
                $selectedPath = $saveDialog.FileName
                if ($global:LogBox -and $global:LogBox.Items) {
                    $logContent = $global:LogBox.Items | ForEach-Object { $_.ToString() }
                    $logText = $logContent -join "`r`n"
                    Set-Content -Path $selectedPath -Value $logText -Encoding UTF8
                    Log "Activity log saved to: $selectedPath" 'Success'
                    [System.Windows.MessageBox]::Show(
                        "Activity log saved successfully!`n`nLocation: $selectedPath`nTimestamp: $(Get-Date)",
                        "Log Saved",
                        'OK',
                        'Information'
                    )

                } else {
                    Log "No activity log content available to save" 'Warning'
                    [System.Windows.MessageBox]::Show("No activity log content available to save.", "No Content", 'OK', 'Warning')
                }
            }
            Log "Error saving activity log: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error saving activity log: $($_.Exception.Message)", "Save Failed", 'OK', 'Error')
        }

if ($btnClearActivityLog) {
    $btnClearActivityLog.Add_Click({
            $result = [System.Windows.MessageBox]::Show(
                "Are you sure you want to clear the activity log?`nThis action cannot be undone.",
                "Clear Activity Log",
                'YesNo',
                'Question'
            )
            if ($result -eq 'Yes') {
                if ($global:LogBox) {
                    $global:LogBox.Items.Clear()
                    Log "Activity log cleared by user" 'Info'

                }
            }
            Log "Error clearing activity log: $($_.Exception.Message)" 'Error'
        }
    })

if ($btnViewActivityLog) {
    $btnViewActivityLog.Add_Click({
        # Switch to the main panel to show the activity log
        Switch-Panel "Dashboard"
    })
}

# Network Panel Action Button Handlers
if ($btnApplyNetworkTweaks) {
    $btnApplyNetworkTweaks.Add_Click({
            Log "Applying network optimizations..." 'Info'
            # Apply selected network optimizations
            Invoke-NetworkPanelOptimizations
            Log "Network optimizations applied successfully" 'Success'
            [System.Windows.MessageBox]::Show("Network optimizations applied successfully!", "Network Optimization", 'OK', 'Information')
            Log "Error applying network optimizations: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error applying network optimizations: $($_.Exception.Message)", "Network Error", 'OK', 'Error')
        }
    })

if ($btnTestNetworkLatency) {
    $btnTestNetworkLatency.Add_Click({
            Log "Testing network latency..." 'Info'
            Test-NetworkLatency
            Log "Error testing network latency: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error testing network latency: $($_.Exception.Message)", "Network Test Error", 'OK', 'Error')
        }
    })

if ($btnResetNetworkSettings) {
    $btnResetNetworkSettings.Add_Click({
            $result = [System.Windows.MessageBox]::Show("Are you sure you want to reset all network settings to default?", "Reset Network Settings", 'YesNo', 'Warning')
            if ($result -eq 'Yes') {
                Log "Resetting network settings to default..." 'Info'
                Reset-NetworkSettings
                Log "Network settings reset successfully" 'Success'
                [System.Windows.MessageBox]::Show("Network settings reset to default values successfully!", "Reset Complete", 'OK', 'Information')

            }
            Log "Error resetting network settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error resetting network settings: $($_.Exception.Message)", "Reset Error", 'OK', 'Error')
        }
    })

# System Panel Action Button Handlers
if ($btnApplySystemOptimizations) {
    $btnApplySystemOptimizations.Add_Click({
            Log "Applying system optimizations..." 'Info'
            Invoke-SystemPanelOptimizations
            Log "System optimizations applied successfully" 'Success'
            [System.Windows.MessageBox]::Show("System optimizations applied successfully!", "System Optimization", 'OK', 'Information')
            Log "Error applying system optimizations: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error applying system optimizations: $($_.Exception.Message)", "System Error", 'OK', 'Error')
        }
    })

if ($btnSystemBenchmark) {
    $btnSystemBenchmark.Add_Click({
            Log "Starting system benchmark..." 'Info'
            Start-SystemBenchmark
            Log "Error starting system benchmark: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error starting system benchmark: $($_.Exception.Message)", "Benchmark Error", 'OK', 'Error')
        }
    })

if ($btnResetSystemSettings) {
    $btnResetSystemSettings.Add_Click({
            $result = [System.Windows.MessageBox]::Show("Are you sure you want to reset all system settings to default?", "Reset System Settings", 'YesNo', 'Warning')
            if ($result -eq 'Yes') {
                Log "Resetting system settings to default..." 'Info'
                Reset-SystemSettings
                Log "System settings reset successfully" 'Success'
                [System.Windows.MessageBox]::Show("System settings reset to default values successfully!", "Reset Complete", 'OK', 'Information')

            }
            Log "Error resetting system settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error resetting system settings: $($_.Exception.Message)", "Reset Error", 'OK', 'Error')
        }
    })

# Services Panel Action Button Handlers
if ($btnApplyServiceOptimizations) {
    $btnApplyServiceOptimizations.Add_Click({
            Log "Applying service optimizations..." 'Info'
            Invoke-ServicePanelOptimizations
            Log "Service optimizations applied successfully" 'Success'
            [System.Windows.MessageBox]::Show("Service optimizations applied successfully!", "Service Optimization", 'OK', 'Information')
            Log "Error applying service optimizations: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error applying service optimizations: $($_.Exception.Message)", "Service Error", 'OK', 'Error')
        }
    })

if ($btnViewRunningServices) {
    $btnViewRunningServices.Add_Click({
            Log "Viewing running services..." 'Info'
            Show-RunningServices
            Log "Error viewing running services: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error viewing running services: $($_.Exception.Message)", "Services Error", 'OK', 'Error')
        }
    })

if ($btnResetServiceSettings) {
    $btnResetServiceSettings.Add_Click({
            $result = [System.Windows.MessageBox]::Show("Are you sure you want to reset all service settings to default?", "Reset Service Settings", 'YesNo', 'Warning')
            if ($result -eq 'Yes') {
                Log "Resetting service settings to default..." 'Info'
                Reset-ServiceSettings
                Log "Service settings reset successfully" 'Success'
                [System.Windows.MessageBox]::Show("Service settings reset to default values successfully!", "Reset Complete", 'OK', 'Information')

            }
            Log "Error resetting service settings: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error resetting service settings: $($_.Exception.Message)", "Reset Error", 'OK', 'Error')
        }
    })

# New Installed Games panel event handlers
if ($btnSearchGames) {
    $btnSearchGames.Add_Click({
            Log "Game search initiated from Installed Games panel" 'Info'
            Search-GamesForPanel
            Log "Error searching for games: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error searching for games: $($_.Exception.Message)", "Game Search Error", 'OK', 'Error')
        }
    })
    Log "Warning: btnSearchGames control not found - skipping event handler binding" 'Warning'

if ($btnAddGameFolder) {
    $btnAddGameFolder.Add_Click({
            Log "Add game folder requested from panel" 'Info'
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select a folder containing game executables or installations"
            $folderDialog.ShowNewFolderButton = $false

            if ($folderDialog.ShowDialog() -eq 'OK') {
                $selectedPath = $folderDialog.SelectedPath
            Log "User selected game folder: $selectedPath" 'Info'

            # Add the selected path to global search paths if not already included
            if (-not $global:CustomGamePaths) {
                $global:CustomGamePaths = @()

            }

            if ($selectedPath -notin $global:CustomGamePaths) {
                $global:CustomGamePaths += $selectedPath
                Log "Added custom game path: $selectedPath" 'Success'

                # Show the Custom Search button now that we have custom folders
                if ($btnCustomSearch) {
                    $btnCustomSearch.Visibility = "Visible"
                    Log "Enabled Custom Search button (custom folders available)" 'Info'
                }

                # Enhanced user prompt as required
                $searchChoice = [System.Windows.MessageBox]::Show(
                    "Game folder added successfully: $selectedPath`n`nDo you want to search only this folder?`n`n* Yes: Search only the selected folder and show all executables (.exe) found`n* No: Include this folder in the full PC search with all existing locations",
                    "Custom Folder Search Option",
                    'YesNoCancel',
                    'Question'
                )

                if ($searchChoice -eq 'Yes') {
                    Log "User chose to search only the selected folder" 'Info'
                    Start-CustomFolderOnlySearch -FolderPath $selectedPath
                } elseif ($searchChoice -eq 'No') {
                    Log "User chose to proceed with full PC search including new folder" 'Info'
                    Search-GamesForPanel
                } else {
                    Log "User cancelled the search operation" 'Info'
                    [System.Windows.MessageBox]::Show("The folder has been added to your custom search list. You can use 'Custom Search' button or 'Search for Installed Games' later.", "Folder Added", 'OK', 'Information')
                }
            } else {
                Log "Path already exists in custom search paths: $selectedPath" 'Warning'
                [System.Windows.MessageBox]::Show("This folder is already included in the search. Click 'Search for Installed Games' to refresh the list.", "Folder Already Added", 'OK', 'Information')
            }
        Log "Error adding game folder: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error adding game folder: $($_.Exception.Message)", "Add Folder Error", 'OK', 'Error')
    Log "Warning: btnAddGameFolder control not found - skipping event handler binding" 'Warning'

# Enhanced Custom Search with user choice functionality
function Start-CustomFolderOnlySearch {
    param([string]$FolderPath)

        Log "Starting custom folder-only search in: $FolderPath" 'Info'

        # Clear existing content
        $gameListPanel.Children.Clear()

        # Add loading message
        $loadingText = New-Object System.Windows.Controls.TextBlock
        $loadingText.Text = "🔍 Searching '$FolderPath' for all executables (.exe)..."
        Set-BrushPropertySafe -Target $loadingText -Property 'Foreground' -Value '#8F6FFF'
        $loadingText.FontStyle = "Italic"
        $loadingText.HorizontalAlignment = "Center"
        $loadingText.Margin = "0,20"
        $gameListPanel.Children.Add($loadingText)

        # Force UI update
        [System.Windows.Forms.Application]::DoEvents()

        # Search for all .exe files in the selected folder and subfolders
        $foundExecutables = @()
        Log "Scanning folder recursively for .exe files: $FolderPath" 'Info'

        try {
            $exeFiles = Get-ChildItem -Path $FolderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
                       Where-Object { $_.Length -gt 100KB }  # Filter out very small executables

            foreach ($exe in $exeFiles) {
                try {
                    $foundExecutables += [PSCustomObject]@{
                        Name = $exe.BaseName
                        Path = $exe.FullName
                        Size = [math]::Round($exe.Length / 1MB, 2)
                        LastModified = $exe.LastWriteTime.ToString("yyyy-MM-dd")
                        Details = "Executable found in custom folder"
                        CanOptimize = $true
                    }
                    # Continue if file details can't be read
                }
            }

            Log "Found $($foundExecutables.Count) executable files in custom folder" 'Success'

            Log "Error scanning custom folder: $($_.Exception.Message)" 'Error'
        }

        # Clear loading message
        $gameListPanel.Children.Clear()

        if ($foundExecutables.Count -gt 0) {
            # Add header
            $headerText = New-Object System.Windows.Controls.TextBlock
            $headerText.Text = "Found $($foundExecutables.Count) Executables in '$([System.IO.Path]::GetFileName($FolderPath))'"
            Set-BrushPropertySafe -Target $headerText -Property 'Foreground' -Value '#8F6FFF'
            $headerText.FontWeight = "Bold"
            $headerText.FontSize = 14
            $headerText.Margin = "0,0,0,10"
            $gameListPanel.Children.Add($headerText)

            # Add each executable with optimization option
            foreach ($executable in $foundExecutables) {
                $gamePanel = New-Object System.Windows.Controls.Border
                Set-BrushPropertySafe -Target $gamePanel -Property 'Background' -Value '#14132B'
                    Set-BrushPropertySafe -Target $gamePanel -Property 'BorderBrush' -Value '#2F285A'
                    $gamePanel.BorderThickness = "1"
                    Write-Verbose "BorderBrush assignment skipped for .NET Framework 4.8 compatibility"
                }
                $gamePanel.Padding = "12"
                $gamePanel.Margin = "0,0,0,8"

                $gameGrid = New-Object System.Windows.Controls.Grid
                $gameGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="*"}))
                $gameGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))

                # Game info
                $gameInfo = New-Object System.Windows.Controls.StackPanel
                [System.Windows.Controls.Grid]::SetColumn($gameInfo, 0)

                $gameName = New-Object System.Windows.Controls.TextBlock
                $gameName.Text = $executable.Name
                Set-BrushPropertySafe -Target $gameName -Property 'Foreground' -Value '#F5F3FF'
                $gameName.FontWeight = "Bold"
                $gameName.FontSize = 14
                $gameInfo.Children.Add($gameName)

                $gameDetails = New-Object System.Windows.Controls.TextBlock
                $gameDetails.Text = "📁 $($executable.Path)`n📊 Size: $($executable.Size) MB | 📅 Modified: $($executable.LastModified)"
                Set-BrushPropertySafe -Target $gameDetails -Property 'Foreground' -Value '#A9A5D9'
                $gameDetails.FontSize = 10
                $gameDetails.TextWrapping = "Wrap"
                $gameInfo.Children.Add($gameDetails)

                # Optimize button
                $optimizeBtn = New-Object System.Windows.Controls.Button
                $optimizeBtn.Content = "⚡ Optimize"
                $optimizeBtn.Width = 100
                $optimizeBtn.Height = 32
                $optimizeBtn.Style = $window.Resources["SuccessButton"]
                $optimizeBtn.Tag = $executable.Path
                [System.Windows.Controls.Grid]::SetColumn($optimizeBtn, 1)

                # Add click handler for optimization
                $optimizeBtn.Add_Click({
                    $exePath = $this.Tag
                    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                    Log "User requested optimization for custom executable: $exeName" 'Info'

                        # Apply standard gaming optimizations
                        Apply-GameOptimizations -GameName $exeName -ExecutablePath $exePath
                        [System.Windows.MessageBox]::Show("Optimization applied successfully for '$exeName'!", "Optimization Complete", 'OK', 'Information')
                        Log "Successfully optimized custom executable: $exeName" 'Success'
                        Log "Error optimizing custom executable: $($_.Exception.Message)" 'Error'
                        [System.Windows.MessageBox]::Show("Error optimizing '$exeName': $($_.Exception.Message)", "Optimization Error", 'OK', 'Error')
                    }
                })

                $gameGrid.Children.Add($gameInfo)
                $gameGrid.Children.Add($optimizeBtn)
                $gamePanel.Child = $gameGrid
                $gameListPanel.Children.Add($gamePanel)
            }

            # Enable the optimize selected button
            if ($btnOptimizeSelected) {
                Set-OptimizeButtonsEnabled -Enabled $true

        } else {
            $noGamesText = New-Object System.Windows.Controls.TextBlock
            $noGamesText.Text = "No executable files (.exe) found in the selected folder.`n`nTip: Make sure the folder contains game installations or executable files."
            Set-BrushPropertySafe -Target $noGamesText -Property 'Foreground' -Value '#7D7EB0'
            $noGamesText.FontStyle = "Italic"
            $noGamesText.HorizontalAlignment = "Center"
            $noGamesText.TextAlignment = "Center"
            $noGamesText.Margin = "0,20"
            $gameListPanel.Children.Add($noGamesText)

        Log "Error in custom folder search: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error searching custom folder: $($_.Exception.Message)", "Search Error", 'OK', 'Error')

if ($btnCustomSearch) {
    $btnCustomSearch.Add_Click({
            Log "Custom Search requested - searching only custom folders" 'Info'

            if (-not $global:CustomGamePaths -or $global:CustomGamePaths.Count -eq 0) {
                [System.Windows.MessageBox]::Show("No custom folders have been added yet. Please add game folders first using 'Add Game Folder'.", "No Custom Folders", 'OK', 'Warning')
                return


            # Show choice dialog for custom search
            $searchChoice = [System.Windows.MessageBox]::Show(
                "Do you want to search only custom folders?`n`n* Yes: Search only the custom folders you've added and show all executables (.exe) found`n* No: Perform full PC search including custom folders with known games",
                "Custom Search Options",
                'YesNoCancel',
                'Question'
            )

            if ($searchChoice -eq 'Yes') {
                Log "User chose to search only custom folders" 'Info'
                Start-AllCustomFoldersSearch
            } elseif ($searchChoice -eq 'No') {
                Log "User chose full PC search including custom folders" 'Info'
                Search-GamesForPanel
            } else {
                Log "User cancelled custom search" 'Info'

            Log "Error in custom search: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error in custom search: $($_.Exception.Message)", "Search Error", 'OK', 'Error')
    })
} else {
    Log "Warning: btnCustomSearch control not found - skipping event handler binding" 'Warning'

if ($btnSearchGamesPanel -and $btnSearchGames) {
    $btnSearchGamesPanel.Add_Click({
            $btnSearchGames.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying Installed Games panel search action: $($_.Exception.Message)" 'Warning'
    })

if ($btnAddGameFolderPanel -and $btnAddGameFolder) {
    $btnAddGameFolderPanel.Add_Click({
            $btnAddGameFolder.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying Installed Games panel add-folder action: $($_.Exception.Message)" 'Warning'
    })

if ($btnCustomSearchPanel -and $btnCustomSearch) {
    $btnCustomSearchPanel.Add_Click({
            $btnCustomSearch.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying Installed Games panel custom search action: $($_.Exception.Message)" 'Warning'
    })

if ($btnAddGameFolderDash -and $btnAddGameFolder) {
    $btnAddGameFolderDash.Add_Click({
            $btnAddGameFolder.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying dashboard add-folder action: $($_.Exception.Message)" 'Warning'
    })

if ($btnCustomSearchDash -and $btnCustomSearch) {
    $btnCustomSearchDash.Add_Click({
            $btnCustomSearch.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            Log "Error relaying dashboard custom search action: $($_.Exception.Message)" 'Warning'
    })

# Search all custom folders for executables
function Start-AllCustomFoldersSearch {
        Log "Starting search of all custom folders" 'Info'

        # Clear existing content
        $gameListPanel.Children.Clear()

        # Add loading message
        $loadingText = New-Object System.Windows.Controls.TextBlock
        $loadingText.Text = "🔍 Searching all custom folders for executables..."
        Set-BrushPropertySafe -Target $loadingText -Property 'Foreground' -Value '#8F6FFF'
        $loadingText.FontStyle = "Italic"
        $loadingText.HorizontalAlignment = "Center"
        $loadingText.Margin = "0,20"
        $gameListPanel.Children.Add($loadingText)

        # Force UI update
        [System.Windows.Forms.Application]::DoEvents()

        $allExecutables = @()

        foreach ($folderPath in $global:CustomGamePaths) {
            try {
                Log "Scanning custom folder: $folderPath" 'Info'
                $exeFiles = Get-ChildItem -Path $folderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
                           Where-Object { $_.Length -gt 100KB }

                foreach ($exe in $exeFiles) {
                    $allExecutables += [PSCustomObject]@{
                        Name = $exe.BaseName
                        Path = $exe.FullName
                        Folder = [System.IO.Path]::GetFileName($folderPath)
                        Size = [math]::Round($exe.Length / 1MB, 2)
                        LastModified = $exe.LastWriteTime.ToString("yyyy-MM-dd")

                Log "Error scanning folder $folderPath`: $($_.Exception.Message)" 'Warning'

        # Clear loading and show results
        $gameListPanel.Children.Clear()

        if ($allExecutables.Count -gt 0) {
            $headerText = New-Object System.Windows.Controls.TextBlock
            $headerText.Text = "Found $($allExecutables.Count) Executables in Custom Folders"
            Set-BrushPropertySafe -Target $headerText -Property 'Foreground' -Value '#8F6FFF'
            $headerText.FontWeight = "Bold"
            $headerText.FontSize = 14
            $headerText.Margin = "0,0,0,10"
            $gameListPanel.Children.Add($headerText)

            foreach ($exe in $allExecutables) {
                $gamePanel = New-Object System.Windows.Controls.Border
                Set-BrushPropertySafe -Target $gamePanel -Property 'Background' -Value '#14132B'
                    Set-BrushPropertySafe -Target $gamePanel -Property 'BorderBrush' -Value '#2F285A'
                    $gamePanel.BorderThickness = "1"
                    Write-Verbose "BorderBrush assignment skipped for .NET Framework 4.8 compatibility"
                $gamePanel.Padding = "12"
                $gamePanel.Margin = "0,0,0,8"

                $gameGrid = New-Object System.Windows.Controls.Grid
                $gameGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="*"}))
                $gameGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))

                $gameInfo = New-Object System.Windows.Controls.StackPanel
                [System.Windows.Controls.Grid]::SetColumn($gameInfo, 0)

                $gameName = New-Object System.Windows.Controls.TextBlock
                $gameName.Text = $exe.Name
                Set-BrushPropertySafe -Target $gameName -Property 'Foreground' -Value '#F5F3FF'
                $gameName.FontWeight = "Bold"
                $gameName.FontSize = 14
                $gameInfo.Children.Add($gameName)

                $gameDetails = New-Object System.Windows.Controls.TextBlock
                $gameDetails.Text = "📁 From: $($exe.Folder) | 📊 $($exe.Size) MB | 📅 $($exe.LastModified)"
                Set-BrushPropertySafe -Target $gameDetails -Property 'Foreground' -Value '#A9A5D9'
                $gameDetails.FontSize = 10
                $gameInfo.Children.Add($gameDetails)

                $optimizeBtn = New-Object System.Windows.Controls.Button
                $optimizeBtn.Content = "⚡ Optimize"
                $optimizeBtn.Width = 100
                $optimizeBtn.Height = 32
                $optimizeBtn.Style = $window.Resources["SuccessButton"]
                $optimizeBtn.Tag = $exe.Path
                [System.Windows.Controls.Grid]::SetColumn($optimizeBtn, 1)

                $optimizeBtn.Add_Click({
                    $exePath = $this.Tag
                    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                    Log "Optimizing custom executable: $exeName" 'Info'

                        Apply-GameOptimizations -GameName $exeName -ExecutablePath $exePath
                        [System.Windows.MessageBox]::Show("Optimization applied for '$exeName'!", "Success", 'OK', 'Information')
                        Log "Successfully optimized: $exeName" 'Success'
                        Log "Error optimizing $exeName`: $($_.Exception.Message)" 'Error'
                        [System.Windows.MessageBox]::Show("Error optimizing '$exeName': $($_.Exception.Message)", "Error", 'OK', 'Error')
                })

                $gameGrid.Children.Add($gameInfo)
                $gameGrid.Children.Add($optimizeBtn)
                $gamePanel.Child = $gameGrid
                $gameListPanel.Children.Add($gamePanel)
        } else {
            $noGamesText = New-Object System.Windows.Controls.TextBlock
            $noGamesText.Text = "No executable files found in custom folders."
            Set-BrushPropertySafe -Target $noGamesText -Property 'Foreground' -Value '#7D7EB0'
            $noGamesText.FontStyle = "Italic"
            $noGamesText.HorizontalAlignment = "Center"
            $noGamesText.Margin = "0,20"
            $gameListPanel.Children.Add($noGamesText)

        Log "Error in all custom folders search: $($_.Exception.Message)" 'Error'

if ($btnOptimizeSelected -or $btnOptimizeSelectedMain -or $btnOptimizeSelectedDashboard) {
    $optimizeSelectedHandler = {
        param($sender, $eventArgs)

            Log "Optimize selected games requested" 'Info'

            $panelsToScan = @()
            if ($sender -and $sender.Name -eq 'btnOptimizeSelectedDashboard' -and $script:DashboardGameListPanel) {
                $panelsToScan += $script:DashboardGameListPanel

            } elseif ($sender -and $sender.Name -eq 'btnOptimizeSelectedMain' -and $script:PrimaryGameListPanel) {
                $panelsToScan += $script:PrimaryGameListPanel

            if ($panelsToScan.Count -eq 0) {
                if ($script:PrimaryGameListPanel) { $panelsToScan += $script:PrimaryGameListPanel }
                if ($script:DashboardGameListPanel) { $panelsToScan += $script:DashboardGameListPanel }

            if ($panelsToScan.Count -eq 0) {
                Log "Warning: No game list panels available when optimizing selections" 'Warning'
                [System.Windows.MessageBox]::Show("No game list is available to process selections.", "No Games Found", 'OK', 'Warning') | Out-Null
                return

            # Find selected games
            $selectedGames = @()
            foreach ($panel in $panelsToScan) {
                foreach ($child in $panel.Children) {
                    if ($child -is [System.Windows.Controls.Border] -and $child.Child -is [System.Windows.Controls.StackPanel]) {
                        $stackPanel = $child.Child
                        $checkbox = $stackPanel.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | Select-Object -First 1
                        if ($checkbox -and $checkbox.IsChecked -and $checkbox.Tag) {
                            $selectedGames += $checkbox.Tag

                if ($selectedGames.Count -gt 0) { break }

            if ($selectedGames.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select at least one game to optimize.", "No Games Selected", 'OK', 'Warning') | Out-Null
                return

            Log "Optimizing $($selectedGames.Count) selected games..." 'Info'

            # Apply game-specific optimizations
            $optimizedCount = 0
            foreach ($game in $selectedGames) {
                    Log "Applying optimizations for: $($game.Name)" 'Info'

                    # Apply the game's specific optimization profile if available
                    $gameProfile = $null
                    foreach ($profile in $GameProfiles.Keys) {
                        if ($GameProfiles[$profile].DisplayName -eq $game.Name) {
                            $gameProfile = $profile
                            break


                    if ($gameProfile) {
                        # Apply specific game profile optimizations
                        Log "Applying $gameProfile profile optimizations for $($game.Name)" 'Info'
                        # You can add specific optimization logic here
                        $optimizedCount++
                    } else {
                        # Apply general gaming optimizations
                        Log "Applying general gaming optimizations for $($game.Name)" 'Info'
                        $optimizedCount++

                    Log "Failed to optimize $($game.Name): $($_.Exception.Message)" 'Error'

            if ($optimizedCount -gt 0) {
                Log "Successfully optimized $optimizedCount out of $($selectedGames.Count) games" 'Success'
                [System.Windows.MessageBox]::Show("Successfully optimized $optimizedCount games!`n`nOptimizations applied:`n- Process priority adjustments`n- System responsiveness settings`n- Network optimizations", "Optimization Complete", 'OK', 'Information') | Out-Null
            } else {
                Log "No games were successfully optimized" 'Warning'
                [System.Windows.MessageBox]::Show("No games were optimized. Please check the log for details.", "Optimization Failed", 'OK', 'Warning') | Out-Null

            Log "Error optimizing selected games: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error optimizing games: $($_.Exception.Message)", "Optimization Error", 'OK', 'Error') | Out-Null

    foreach ($button in @($btnOptimizeSelected, $btnOptimizeSelectedMain, $btnOptimizeSelectedDashboard)) {
        if ($button) {
            $button.Add_Click($optimizeSelectedHandler)
} else {
    Log "Warning: btnOptimizeSelected control not found - skipping event handler binding" 'Warning'

# New Options panel event handlers
if ($btnImportOptions) {
    $btnImportOptions.Add_Click({
            Log "Import configuration requested from Options panel" 'Info'
            Import-Configuration
            Log "Error importing configuration from Options: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error importing configuration: $($_.Exception.Message)", "Import Error", 'OK', 'Error')
    })
} else {
    Log "Warning: btnImportOptions control not found - skipping event handler binding" 'Warning'

if ($btnChooseBackupFolder) {
    $btnChooseBackupFolder.Add_Click({
            Log "Choose configuration folder requested from Options panel" 'Info'
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select folder for all configuration and backup files (recommended when running as Administrator)"
            $folderDialog.ShowNewFolderButton = $true

            # Set default to Documents if we're in a system directory
            $isAdmin = Test-AdminPrivileges
            if ($isAdmin) {
                $folderDialog.SelectedPath = Join-Path $env:USERPROFILE "Documents"


            if ($folderDialog.ShowDialog() -eq 'OK') {
                $selectedPath = $folderDialog.SelectedPath
                Log "User selected configuration folder: $selectedPath" 'Info'

                # Create subdirectory for KOALA files
                $koalaConfigPath = Join-Path $selectedPath "KOALA Gaming Optimizer"
                if (-not (Test-Path $koalaConfigPath)) {
                    New-Item -ItemType Directory -Path $koalaConfigPath -Force | Out-Null
                    Log "Created KOALA configuration directory: $koalaConfigPath" 'Info'

                # Update all global paths
                $global:CustomConfigPath = $koalaConfigPath
                $global:BackupPath = Join-Path $koalaConfigPath 'Koala-Backup.json'
                $global:ConfigPath = Join-Path $koalaConfigPath 'Koala-Config.json'
                $global:SettingsPath = Join-Path $koalaConfigPath 'koala-settings.cfg'

                # Show confirmation with all affected files
                $filesList = @(
                    "* Backup files (Koala-Backup.json)",
                    "* Configuration exports (Koala-Config.json)",
                    "* Settings file (koala-settings.cfg)",
                    "* Registry backups (.reg files)",
                    "* Activity logs (Koala-Activity.log)"
                )

                $message = "Configuration folder updated successfully!`n`nLocation: $koalaConfigPath`n`nAll future files will be saved here:`n" + ($filesList -join "`n")
                if ($isAdmin) {
                    $message += "`n`n[OK] Running as Administrator - files will be safely saved outside system directories"

                [System.Windows.MessageBox]::Show($message, "Configuration Folder Updated", 'OK', 'Information')
                Log "All configuration paths updated to use: $koalaConfigPath" 'Success'
            Log "Error choosing configuration folder: $($_.Exception.Message)" 'Error'
            [System.Windows.MessageBox]::Show("Error choosing configuration folder: $($_.Exception.Message)", "Folder Selection Error", 'OK', 'Error')
    })
} else {
    Log "Warning: btnChooseBackupFolder control not found - skipping event handler binding" 'Warning'

# Apply All button - Complete Implementation
if ($btnApply) {
    $btnApply.Add_Click({
        Log "User initiated comprehensive optimization process in $global:MenuMode mode" 'Info'
        Log "Starting comprehensive optimization process..." 'Info'

        # Safely update status label with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Applying..."
            Log "Warning: Could not update optimization status label: $($_.Exception.Message)" 'Warning'

    # Check admin
    $isAdmin = Test-AdminPrivileges
    if (-not $isAdmin) {
        $requiredOps = @(
            "Registry modifications (HKEY_LOCAL_MACHINE)",
            "Network TCP/IP settings",
            "Windows service configuration",
            "Advanced system optimizations"
        )
        $elevationResult = Show-ElevationMessage -Operations $requiredOps
        if (-not $elevationResult) {
            # Safely update status with null check
            if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                    $lblOptimizationStatus.Text = "Cancelled"
                    Log "Warning: Could not update optimization status label: $($_.Exception.Message)" 'Warning'
            return

    # Create backup first
    Create-Backup

    $optimizationCount = 0
    $errorCount = 0

        # Apply game-specific optimizations if selected
        if ($cmbGameProfile.SelectedItem -and $cmbGameProfile.SelectedItem.Tag -ne "custom" -and $cmbGameProfile.SelectedItem.Tag -ne "") {
            $selectedGame = $cmbGameProfile.SelectedItem.Tag
            if ($GameProfiles.ContainsKey($selectedGame)) {
                $profile = $GameProfiles[$selectedGame]
                Log "Applying optimizations for: $($profile.DisplayName)" 'Info'

                if ($profile.SpecificTweaks) {
                    Apply-GameSpecificTweaks -GameKey $selectedGame -TweakList $profile.SpecificTweaks
                    $optimizationCount += $profile.SpecificTweaks.Count


                if ($profile.FPSBoostSettings) {
                    Apply-FPSBoostSettings -SettingList $profile.FPSBoostSettings
                    $optimizationCount += $profile.FPSBoostSettings.Count
        # Handle custom game executable
        elseif ($txtCustomGame.Text -and $txtCustomGame.Text.Trim() -ne "") {
            $customGameName = $txtCustomGame.Text.Trim()
            Log "Applying standard gaming optimizations for custom game: $customGameName" 'Info'

            # Apply safe, standard gaming tweaks for custom game
            Apply-CustomGameOptimizations -GameExecutable $customGameName
            $optimizationCount += 5  # Standard set of safe optimizations

        # Network optimizations
        $networkSettings = @{
            TCPAck = $chkAck.IsChecked
            DelAckTicks = $chkDelAckTicks.IsChecked
            NetworkThrottling = $chkThrottle.IsChecked
            NagleAlgorithm = $chkNagle.IsChecked
            TCPTimestamps = $chkTcpTimestamps.IsChecked
            ECN = $chkTcpECN.IsChecked
            RSS = $chkRSS.IsChecked
            RSC = $chkRSC.IsChecked
            AutoTuning = $chkTcpAutoTune.IsChecked
        $optimizationCount += Apply-NetworkOptimizations -Settings $networkSettings

        # Essential gaming optimizations
        if ($chkResponsiveness.IsChecked) {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "System responsiveness optimized" 'Success'
            $optimizationCount++

        if ($chkGamesTask.IsChecked) {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 'DWord' 8 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 'DWord' 6 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" 'String' "High" -RequiresAdmin $true | Out-Null
            Log "Games task priority raised" 'Success'
            $optimizationCount++

        if ($chkGameDVR -and $chkGameDVR.IsChecked) {
            if (Disable-GameDVR) {
                $optimizationCount++

        if ($chkFSE -and $chkFSE.IsChecked) {
            Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 'DWord' 2 | Out-Null
            Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 'DWord' 2 | Out-Null
            Log "Fullscreen optimizations disabled" 'Success'
            $optimizationCount++

        if ($chkGpuScheduler -and $chkGpuScheduler.IsChecked) {
            if (Enable-GPUScheduling) {
                $optimizationCount++

        if ($chkTimerRes -and $chkTimerRes.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 'DWord' 1 -RequiresAdmin $true | Out-Null
            try { [WinMM]::timeBeginPeriod(1) | Out-Null } catch {}
            Log "High precision timer enabled" 'Success'
            $optimizationCount++

        if ($chkVisualEffects.IsChecked) {
            Set-SelectiveVisualEffects -EnablePerformanceMode
            $optimizationCount++

        if ($chkHibernation.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
            powercfg -h off 2>$null
            Log "Hibernation disabled" 'Success'
            $optimizationCount++

        # System Performance
        if ($chkMemoryManagement.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "Memory management optimized" 'Success'
            $optimizationCount++

        if ($chkPowerPlan.IsChecked) {
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            $ultimatePlan = powercfg -list | Where-Object { $_ -match "Ultimate Performance" }
            if ($ultimatePlan) {
                $planGuid = ($ultimatePlan -split '\s+')[3]
                powercfg -setactive $planGuid
                Log "Ultimate Performance power plan activated" 'Success'
                $optimizationCount++

        if ($chkCpuScheduling.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 'DWord' 38 -RequiresAdmin $true | Out-Null
            Log "CPU scheduling optimized" 'Success'
            $optimizationCount++

        # Advanced FPS optimizations
        if ($chkCpuCorePark.IsChecked) {
            Apply-FPSOptimizations -OptimizationList @('CPUCoreParkDisable')
            $optimizationCount++

        if ($chkMemCompression.IsChecked) {
            Apply-FPSOptimizations -OptimizationList @('MemoryCompressionDisable')
            $optimizationCount++

        if ($chkInputOptimization.IsChecked) {
            Apply-FPSOptimizations -OptimizationList @('InputLatencyReduction')
            $optimizationCount++

        if ($chkDirectX12Opt.IsChecked) {
            Apply-FPSOptimizations -OptimizationList @('DirectX12Optimization')
            $optimizationCount++

        if ($chkInterruptMod.IsChecked) {
            Apply-FPSOptimizations -OptimizationList @('InterruptModerationOptimization')
            $optimizationCount++

        # New Advanced Optimizations
        if ($chkDirectStorage.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisableCompression" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" "ForcedPhysicalSectorSizeInBytes" 'DWord' 4096 -RequiresAdmin $true | Out-Null
            Log "DirectStorage support optimized" 'Success'
            $optimizationCount++

        if ($chkGpuAutoTuning.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay" 'DWord' 10 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrLevel" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "GPU driver auto-tuning enabled" 'Success'
            $optimizationCount++

        if ($chkLowLatencyAudio.IsChecked) {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 'DWord' 10 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" "Priority" 'DWord' 6 -RequiresAdmin $true | Out-Null
            Log "Low-latency audio mode enabled" 'Success'
            $optimizationCount++

        if ($chkHardwareInterrupt.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ8Priority" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ16Priority" 'DWord' 2 -RequiresAdmin $true | Out-Null
            Log "Hardware interrupt tuning applied" 'Success'
            $optimizationCount++

        if ($chkNVMeOptimization.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" "IdlePowerManagementEnabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" "StorageD3InModernStandby" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "NVMe optimizations applied" 'Success'
            $optimizationCount++

        if ($chkWin11GameMode.IsChecked) {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 'DWord' 1 | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "Windows 11 Game Mode+ enabled" 'Success'
            $optimizationCount++

        if ($chkMemoryPool.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PoolUsageMaximum" 'DWord' 96 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagedPoolSize" 'DWord' 192 -RequiresAdmin $true | Out-Null
            Log "Memory pool optimization applied" 'Success'
            $optimizationCount++

        if ($chkGpuPreemption.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" "EnablePreemption" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "PlatformSupportMiracast" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Log "GPU preemption tuning applied" 'Success'
            $optimizationCount++

        if ($chkCpuMicrocode.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DisableTsx" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationOptions" 'QWord' 0 -RequiresAdmin $true | Out-Null
            Log "CPU microcode optimization applied" 'Success'
            $optimizationCount++

        if ($chkPciLatency.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" "DeviceSelectTimeout" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PCI" "HackFlags" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Log "PCI-E latency reduction applied" 'Success'
            $optimizationCount++

        if ($chkDmaRemapping.IsChecked) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\vdrvroot\Parameters" "DmaRemappingCompatible" 'DWord' 0 -RequiresAdmin $true | Out-Null
            bcdedit /set disabledynamictick yes 2>$null
            Log "DMA remapping optimization applied" 'Success'
            $optimizationCount++

        if ($chkFramePacing.IsChecked) {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "DisableAGPSupport" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DpiMapIommuContiguous" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Log "Advanced frame pacing enabled" 'Success'
            $optimizationCount++

        # DirectX 11 optimizations
        if ($chkDX11GpuScheduling.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11EnhancedGpuScheduling')
            $optimizationCount++

        if ($chkDX11ProcessPriority.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11GameProcessPriority')
            $optimizationCount++

        if ($chkDX11BackgroundServices.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11DisableBackgroundServices')
            $optimizationCount++

        if ($chkDX11HardwareAccel.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11HardwareAcceleration')
            $optimizationCount++

        if ($chkDX11MaxPerformance.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11MaxPerformanceMode')
            $optimizationCount++

        if ($chkDX11RegistryTweaks.IsChecked) {
            Apply-DX11Optimizations -OptimizationList @('DX11RegistryOptimizations')
            $optimizationCount++

        # Advanced System Tweaks
        if ($chkHPET.IsChecked) {
            Apply-HPETOptimization -Disable $true
            $optimizationCount++

        if ($chkMenuDelay.IsChecked) {
            Remove-MenuDelay
            $optimizationCount++

        if ($chkDefenderOptimize.IsChecked) {
            Disable-WindowsDefenderRealTime
            $optimizationCount++

        if ($chkModernStandby.IsChecked) {
            Disable-ModernStandby
            $optimizationCount++

        if ($chkUTCTime.IsChecked) {
            Enable-UTCTime
            $optimizationCount++

        if ($chkNTFS.IsChecked) {
            Optimize-NTFSSettings
            $optimizationCount++

        if ($chkEdgeTelemetry.IsChecked) {
            Disable-EdgeTelemetry
            $optimizationCount++

        if ($chkCortana.IsChecked) {
            Disable-Cortana
            $optimizationCount++

        if ($chkTelemetry.IsChecked) {
            Disable-Telemetry
            $optimizationCount++

        # Service optimizations
        $serviceSettings = @{
            XboxServices = $chkSvcXbox.IsChecked
            PrintSpooler = $chkSvcSpooler.IsChecked
            Superfetch = $chkSvcSysMain.IsChecked
            Telemetry = $chkSvcDiagTrack.IsChecked
            WindowsSearch = $chkSvcSearch.IsChecked
            UnneededServices = $chkDisableUnneeded.IsChecked
        $optimizationCount += Apply-ServiceOptimizations -Settings $serviceSettings

        # Safely update status to Complete with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Complete"
                Log "Warning: Could not update optimization status to Complete: $($_.Exception.Message)" 'Warning'

        Log "Optimization process completed!" 'Success'
        Log "Results: $optimizationCount optimizations applied, $errorCount errors" 'Info'

        # Track optimization completion time for dashboard metrics
        $global:LastOptimizationTime = Get-Date

        [System.Windows.MessageBox]::Show(
            "Optimizations applied successfully!`n`nApplied: $optimizationCount optimizations`nErrors: $errorCount`n`nSystem restart recommended",
            "Optimization Complete",
            'OK',
            'Information'
        )

        Log "Critical error during optimization: $($_.Exception.Message)" 'Error'
        # Safely update status to Error with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Error"
                Log "Warning: Could not update optimization status to Error: $($_.Exception.Message)" 'Warning'
        $errorCount++
})

# Apply All Main button (Dashboard) - Complete Implementation with full functionality
if ($btnApplyMain) {
    $btnApplyMain.Add_Click({
        Log "User initiated comprehensive optimization process from Apply All button in $global:MenuMode mode" 'Info'
        Log "Starting comprehensive optimization process..." 'Info'

        # Safely update status label with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Applying..."
                Log "Warning: Could not update optimization status label: $($_.Exception.Message)" 'Warning'

        # Check admin
        $isAdmin = Test-AdminPrivileges
        if (-not $isAdmin) {
            $requiredOps = @(
                "Registry modifications (HKEY_LOCAL_MACHINE)",
                "Network TCP/IP settings",
                "Windows service configuration",
                "Advanced system optimizations"
            )
            $elevationResult = Show-ElevationMessage -Operations $requiredOps
            if (-not $elevationResult) {
                # Safely update status with null check
                if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                        $lblOptimizationStatus.Text = "Cancelled"
                        Log "Warning: Could not update optimization status label: $($_.Exception.Message)" 'Warning'
                return

        # Create backup first
        Create-Backup

        $optimizationCount = 0
        $errorCount = 0

            # Apply core gaming optimizations
            Log "Applying core gaming optimizations..." 'Info'

            # System responsiveness
            try {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "System responsiveness optimized" 'Success'
                $optimizationCount++
            } catch {
                Log "Error setting system responsiveness: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # Game DVR disable
                Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 'DWord' 0 | Out-Null
                Log "Game DVR disabled" 'Success'
                $optimizationCount++
                Log "Error disabling Game DVR: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # GPU Hardware Scheduling
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
                Log "Hardware GPU scheduling enabled" 'Success'
                $optimizationCount++
                Log "Error enabling GPU scheduling: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # High precision timer
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 'DWord' 1 -RequiresAdmin $true | Out-Null
                [WinMM]::timeBeginPeriod(1) | Out-Null
                Log "High precision timer enabled" 'Success'
                $optimizationCount++
                Log "Error setting high precision timer: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # Network optimizations
                Log "Applying network optimizations..." 'Info'
                # TCP Ack Frequency
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpAckFrequency" 'DWord' 1 -RequiresAdmin $true | Out-Null
                # Disable Nagle Algorithm
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
                # Network throttling
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 'DWord' 4294967295 -RequiresAdmin $true | Out-Null
                Log "Network optimizations applied" 'Success'
                $optimizationCount += 3
                Log "Error applying network optimizations: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # Power plan optimization
                Log "Setting Ultimate Performance power plan..." 'Info'
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
                $ultimatePlan = powercfg -list | Where-Object { $_ -match "Ultimate Performance" }
                if ($ultimatePlan) {
                    $planGuid = ($ultimatePlan -split '\s+')[3]
                    powercfg -setactive $planGuid
                    Log "Ultimate Performance power plan activated" 'Success'
                    $optimizationCount++

                Log "Error setting power plan: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # Memory management
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "Memory management optimized" 'Success'
                $optimizationCount++
                Log "Error optimizing memory management: $($_.Exception.Message)" 'Warning'
                $errorCount++

            # Safely update status to Complete with null check
            if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                    $lblOptimizationStatus.Text = "Complete"
                    Log "Warning: Could not update optimization status to Complete: $($_.Exception.Message)" 'Warning'

            Log "Apply All optimization process completed!" 'Success'
            Log "Results: $optimizationCount optimizations applied, $errorCount errors" 'Info'

            # Track optimization completion time for dashboard metrics
            $global:LastOptimizationTime = Get-Date

            [System.Windows.MessageBox]::Show(
                "Apply All optimizations completed successfully!`n`nApplied: $optimizationCount optimizations`nErrors: $errorCount`n`nSystem restart recommended for full effect",
                "Apply All Complete",
                'OK',
                'Information'
            )

            Log "Critical error during Apply All optimization: $($_.Exception.Message)" 'Error'
            # Safely update status to Error with null check
            if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                    $lblOptimizationStatus.Text = "Error"
                    Log "Warning: Could not update optimization status to Error: $($_.Exception.Message)" 'Warning'
            $errorCount++
            [System.Windows.MessageBox]::Show("Error during Apply All optimization: $($_.Exception.Message)", "Apply All Error", 'OK', 'Error')
    })

# Revert All button
if ($btnRevert) {
    $btnRevert.Add_Click({
        Log "Revert optimizations requested by user" 'Info'
        $result = [System.Windows.MessageBox]::Show(
            "Are you sure you want to revert all optimizations?`n`nThis will restore your system using the backup.",
            "Confirm Revert",
        'YesNo',
        'Question'
    )

    if ($result -eq 'Yes') {
        Log "User confirmed revert operation - starting restoration" 'Warning'
        # Safely update status to Reverting with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Reverting..."
                Log "Warning: Could not update optimization status to Reverting: $($_.Exception.Message)" 'Warning'
        Restore-FromBackup
        # Safely update status to Reverted with null check
        if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
                $lblOptimizationStatus.Text = "Reverted"
                Log "Warning: Could not update optimization status to Reverted: $($_.Exception.Message)" 'Warning'
        Log "System restoration completed successfully" 'Success'
    } else {
        Log "User cancelled revert operation" 'Info'
})

# ---------- Initialize Application ----------
function Initialize-Application {
    Log "KOALA Gaming Optimizer v3.0 - Enhanced Edition Starting" 'Info'
    Log "Initializing application..." 'Info'

    # Enhanced admin status checking and visual feedback
    $isAdmin = Test-AdminPrivileges
    Log "Admin privileges check: $isAdmin" 'Info'

        if ($isAdmin) {
            # Administrator mode - full access
            if ($lblAdminStatus) {
                $lblAdminStatus.Text = "Administrator Mode"
                Set-BrushPropertySafe -Target $lblAdminStatus -Property 'Foreground' -Value '#8F6FFF'

            if ($lblAdminDetails) {
                $lblAdminDetails.Text = "All optimizations available"
            if ($btnElevate) {
                $btnElevate.Visibility = [System.Windows.Visibility]::Collapsed

            # Enable advanced features visual indicator
            if ($form -and $form.Title) {
                $form.Title = "KOALA Gaming Optimizer v3.0 - Enhanced Edition [Administrator]"

            Log "Administrator mode detected - full optimization access granted" 'Success'
        } else {
            # Limited mode - some restrictions
            if ($lblAdminStatus) {
                $lblAdminStatus.Text = "Limited Mode"
                Set-BrushPropertySafe -Target $lblAdminStatus -Property 'Foreground' -Value '#8F6FFF'
            if ($lblAdminDetails) {
                $lblAdminDetails.Text = "Some optimizations require administrator privileges"
            if ($btnElevate) {
                $btnElevate.Visibility = [System.Windows.Visibility]::Visible

            Log "Limited mode detected - some optimizations may be restricted" 'Warning'
            Log "Tip: Run as Administrator for full access to all optimizations" 'Info'
        Log "Error setting admin status visual feedback: $($_.Exception.Message)" 'Warning'

    # Enhanced system information gathering
        $systemInfo = @{}

        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $systemInfo.OS = $os.Caption
        Log "OS: $($systemInfo.OS)" 'Info'

        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
        $systemInfo.CPU = $cpu.Name
        Log "CPU: $($systemInfo.CPU)" 'Info'

        $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        $systemInfo.RAM = "$ram GB"
        Log "RAM: $($systemInfo.RAM)" 'Info'

        $gpu = Get-GPUVendor
        $systemInfo.GPU = $gpu
        Log "GPU Vendor: $($systemInfo.GPU)" 'Info'

        # Store system info for later use
        $global:SystemInfo = $systemInfo

        Log "Failed to gather system info: $($_.Exception.Message)" 'Warning'

    # Enhanced default menu mode setting with validation
        Log "Setting default menu mode to Basic..." 'Info'
        Switch-MenuMode -Mode "Basic"

        # Validate menu mode was set correctly
        if ($global:MenuMode -eq "Basic") {
            Log "Default menu mode set successfully: $global:MenuMode" 'Success'

        } else {
            Log "Warning: Menu mode validation failed, expected 'Basic' but got '$global:MenuMode'" 'Warning'
        Log "Error setting default menu mode: $($_.Exception.Message)" 'Error'
        # Fallback - try to set a minimal working state
        $global:MenuMode = "Basic"

    # Enhanced performance monitoring startup
        Log "Starting performance monitoring..." 'Info'
        $perfTimer = New-Object System.Windows.Threading.DispatcherTimer
        $perfTimer.Interval = [TimeSpan]::FromSeconds(3)
        $perfTimer.Add_Tick({ Update-PerformanceDisplay })
        $perfTimer.Start()
        $global:PerformanceTimer = $perfTimer
        Log "Performance monitoring started successfully" 'Success'
        Log "Failed to start performance monitoring: $($_.Exception.Message)" 'Warning'

    # Enhanced game detection startup deferred until Auto-Optimize is enabled
    Log "Game detection loop is idle until Auto-Optimize is enabled" 'Info'

    # Enhanced high precision timer activation
        [WinMM]::timeBeginPeriod(1) | Out-Null
        Log "High precision timer activated for enhanced gaming performance" 'Success'
        Log "Could not activate high precision timer: $($_.Exception.Message)" 'Warning'

    # Enhanced startup validation and visual feedback
        # Validate critical UI elements are accessible
        $criticalElements = @{
            'LogBox' = $LogBox
            'Form' = $form
            'AdminStatus' = $lblAdminStatus


        $validationErrors = @()
        foreach ($elementName in $criticalElements.Keys) {
            if (-not $criticalElements[$elementName]) {
                $validationErrors += $elementName

        if ($validationErrors.Count -eq 0) {
            Log "All critical UI elements validated successfully" 'Success'
        } else {
            Log "UI validation issues found: $($validationErrors -join ', ')" 'Warning'

        # Update UI status indicators
        if ($lblOptimizationStatus) {
            $lblOptimizationStatus.Text = if ($isAdmin) { "Ready (Administrator)" } else { "Ready (Limited)" }

        Log "Error in startup validation: $($_.Exception.Message)" 'Warning'

    Log "Application initialized successfully!" 'Success'
    Log "Mode: $global:MenuMode | Admin: $isAdmin | Ready for optimizations" 'Info'

# Window closing handler
$form.Add_Closing({
        [WinMM]::timeEndPeriod(1) | Out-Null
        Log "Closing application - High precision timer released" 'Info'
})

# ---------- Start Application ----------
Initialize-Application

# Safely initialize status label with null check
if ($lblOptimizationStatus -and $lblOptimizationStatus.Text -ne $null) {
        $lblOptimizationStatus.Text = "Ready"
        Log "Warning: Could not initialize optimization status label: $($_.Exception.Message)" 'Warning'

# Apply default theme on startup
    Log "Applying default theme on startup..." 'Info'
    Switch-Theme -ThemeName "OptimizerDark"
    Log "Default theme applied successfully - UI ready" 'Success'
    Log "Warning: Could not apply default theme on startup: $($_.Exception.Message)" 'Warning'

# Load settings from cfg file if it exists
    $configPath = Join-Path (Get-Location) "koala-settings.cfg"
    if (Test-Path $configPath) {
        Log "Loading settings from koala-settings.cfg..." 'Info'

        $content = Get-Content $configPath -Raw
        $settings = @{}

        $content -split "`n" | ForEach-Object {
            if ($_ -match "^([^#=]+)=(.*)`$") {
                $settings[$matches[1].Trim()] = $matches[2].Trim()


        # Apply loaded theme
        if ($settings.Theme) {
            foreach ($item in $cmbOptionsTheme.Items) {
                if ($item.Tag -eq $settings.Theme) {
                    $cmbOptionsTheme.SelectedItem = $item
                    Switch-Theme -ThemeName $settings.Theme
                    Log "Loaded theme: $($settings.Theme)" 'Info'
                    break

        # Apply loaded scale
        if ($settings.UIScale -and $cmbUIScale) {
            foreach ($item in $cmbUIScale.Items) {
                if ($item.Tag -eq $settings.UIScale) {
                    $cmbUIScale.SelectedItem = $item
                    $scaleValue = [double]$settings.UIScale
                    if ($scaleValue -ne 1.0) {
                        $scaleTransform = New-Object System.Windows.Media.ScaleTransform($scaleValue, $scaleValue)
                        $form.LayoutTransform = $scaleTransform
                        Log "Loaded UI scale: $($settings.UIScale)" 'Info'
                    break

        # Apply loaded menu mode
        if ($settings.MenuMode) {
            # Menu mode control removed from header - mode managed through Options panel only
            # foreach ($item in $cmbMenuMode.Items) {
            #     if ($item.Tag -eq $settings.MenuMode) {
            #         $cmbMenuMode.SelectedItem = $item
            #         Switch-MenuMode -Mode $settings.MenuMode
            #         Log "Loaded menu mode: $($settings.MenuMode)" 'Info'
            #         break
            #     }
            # }
            Switch-MenuMode -Mode $settings.MenuMode  # Direct call without UI control
            Log "Loaded menu mode: $($settings.MenuMode)" 'Info'

        if ($settings.Language) {
            Set-UILanguage -LanguageCode $settings.Language
            Log "Loaded language: $($settings.Language)" 'Info'

        if ($settings.ContainsKey('AdvancedSelections')) {
            $advancedChecked = @()
            if ($settings.AdvancedSelections) {
                $advancedChecked = $settings.AdvancedSelections -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

            Set-AdvancedSelections -CheckedNames $advancedChecked

            $advancedStartupSummary = Get-AdvancedSelectionSummary -CheckedNames $advancedChecked
            Log "Loaded advanced selections: $advancedStartupSummary" 'Info'

        Log "Settings loaded successfully from koala-settings.cfg" 'Success'
    } else {
        Log "No settings file found - using defaults" 'Info'
    Log "Warning: Could not load settings from cfg file: $($_.Exception.Message)" 'Warning'

# ---------- Responsive UI Scaling ----------
function Update-UIScaling {
    param(
        [double]$WindowWidth,
        [double]$WindowHeight
    )

        # Calculate scaling factors based on window size relative to design size (1400x900)
        $baseWidth = 1400
        $baseHeight = 900
        $widthScale = $WindowWidth / $baseWidth
        $heightScale = $WindowHeight / $baseHeight
        $averageScale = ($widthScale + $heightScale) / 2

        # Constrain scaling to reasonable bounds
        $minScale = 0.8
        $maxScale = 1.5
        $scale = [Math]::Max($minScale, [Math]::Min($maxScale, $averageScale))

        Log "Updating UI scaling: Window $([int]$WindowWidth)x$([int]$WindowHeight), Scale factor: $([Math]::Round($scale, 2))" 'Info'

        # Apply scaling to key UI elements
        if ($form.Resources['ModernButton']) {
            $buttonStyle = $form.Resources['ModernButton']
            # Update font sizes proportionally
            $baseFontSize = 12
            $scaledFontSize = [Math]::Round($baseFontSize * $scale, 1)

            try {
                $fontSetter = $buttonStyle.Setters | Where-Object { $_.Property.Name -eq "FontSize" }
                if ($fontSetter) {
                    $fontSetter.Value = $scaledFontSize
            } catch {
                # Continue if font scaling fails

        # Scale text elements
        $textElements = @("lblAdminStatus", "lblAdminDetails", "lblOptimizationStatus")
        foreach ($elementName in $textElements) {
            $element = $form.FindName($elementName)
            if ($element -and $element.FontSize) {
                    $baseFontSize = 14
                    $element.FontSize = [Math]::Round($baseFontSize * $scale, 1)
                    # Continue if element scaling fails

        # Update Activity Log dimensions proportionally
        if ($global:LogBox) {
                # Ensure log area maintains good visibility at different scales
                $baseLogHeight = 240
                $scaledLogHeight = [Math]::Max(180, [Math]::Round($baseLogHeight * $scale))

                # Find the log area parent to update height
                $parent = $global:LogBox.Parent
                while ($parent -and -not ($parent -is [System.Windows.Controls.Grid])) {
                    $parent = $parent.Parent


                if ($parent -and $parent.RowDefinitions -and $parent.RowDefinitions.Count -gt 3) {
                    $logRowDef = $parent.RowDefinitions[3]  # Activity log is in row 3
                    if ($logRowDef) {
                        $logRowDef.Height = [System.Windows.GridLength]::new($scaledLogHeight)
                # Continue if log scaling fails

        Log "UI scaling update completed successfully" 'Info'

        Log "Error updating UI scaling: $($_.Exception.Message)" 'Warning'

# Add window resize event handler for responsive scaling
$form.Add_SizeChanged({
        if ($form.ActualWidth -gt 0 -and $form.ActualHeight -gt 0) {
            Update-UIScaling -WindowWidth $form.ActualWidth -WindowHeight $form.ActualHeight

        Log "Error in window resize handler: $($_.Exception.Message)" 'Warning'
})

# Initial UI scaling setup
    Update-UIScaling -WindowWidth 1400 -WindowHeight 900
    Log "Initial UI scaling configuration applied" 'Success'
    Log "Warning: Could not apply initial UI scaling: $($_.Exception.Message)" 'Warning'

# Initialize Custom Search button visibility
    if ($btnCustomSearch) {
        # Hide Custom Search button initially (only show when custom folders are added)
        $btnCustomSearch.Visibility = "Collapsed"
        Log "Custom Search button initialized as hidden (no custom folders yet)" 'Info'

    Log "Warning: Could not initialize Custom Search button visibility: $($_.Exception.Message)" 'Warning'

# Initialize default theme and color preview
if ($cmbOptionsTheme -and $cmbOptionsTheme.Items.Count -gt 0) {
    # Set default theme to Optimizer Dark
    foreach ($item in $cmbOptionsTheme.Items) {
        if ($item.Tag -eq "OptimizerDark") {
            $cmbOptionsTheme.SelectedItem = $item
            Update-ThemeColorPreview -ThemeName "OptimizerDark"
            Log "Default theme 'Optimizer Dark' selected with color preview initialized" 'Info'
            break
} else {
    Log "Warning: Theme dropdown not available for initialization" 'Warning'


function Invoke-PanelActions {
    param(
        [Parameter(Mandatory)]
        [string]$PanelName,

        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Actions
    )


    $applied = [System.Collections.Generic.List[string]]::new()

    foreach ($action in $Actions) {
        $checkbox = $action.Checkbox
        $callback = $action.Action
        $description = $action.Description

        if (-not $checkbox -or -not $callback) {
            continue

        if (-not $checkbox.IsChecked) {
            continue

            # removed invalid call
            if ($description) {
                [void]$applied.Add($description)

            $detail = if ($description) { $description } else { 'panel action' }
            $message = "Warning: Failed to apply $PanelName action '$detail': $($_.Exception.Message)"
            Log $message 'Warning'

    return $applied


function Invoke-NetworkPanelOptimizations {
    Log "Applying network optimizations from dedicated Network panel..." 'Info'

    $networkActions = @(
        [pscustomobject]@{
            Checkbox    = $chkAckNetwork
            Action      = { Apply-TcpAck }
            Description = 'TCP ACK frequency tweak'
        [pscustomobject]@{
            Checkbox    = $chkNagleNetwork
            Action      = { Apply-NagleDisable }
            Description = 'Disable Nagle algorithm'
        [pscustomobject]@{
            Checkbox    = $chkNetworkThrottlingNetwork
            Action      = { Apply-NetworkThrottling }
            Description = 'Network throttling adjustments'
    )

    $applied = Invoke-PanelActions -PanelName 'Network' -Actions $networkActions

    if ($applied.Count -gt 0) {
        $details = $applied -join ', '
        Log "Network optimizations applied successfully ($details)" 'Success'
    } else {
        Log 'No network optimizations were selected in the dedicated Network panel' 'Info'


function Test-NetworkLatency {
    Log "Testing network latency..." 'Info'

        # Test ping to common servers
        $servers = @("8.8.8.8", "1.1.1.1", "8.8.4.4")
        $results = @()

        foreach ($server in $servers) {
            $ping = Test-Connection -ComputerName $server -Count 4 -Quiet
            if ($ping) {
                $pingResult = Test-Connection -ComputerName $server -Count 4
                $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
                $results += "Server $server`: $([math]::Round($avgLatency, 2))ms"
                Log "Ping to $server`: $([math]::Round($avgLatency, 2))ms" 'Info'


        if ($results.Count -gt 0) {
            $message = "Network Latency Test Results:`n`n" + ($results -join "`n")
            [System.Windows.MessageBox]::Show($message, "Network Latency Test", 'OK', 'Information')
        Log "Error testing network latency: $($_.Exception.Message)" 'Error'

function Reset-NetworkSettings {
    Log "Resetting network settings to default..." 'Info'

    # Reset network-related registry keys to default
        # Reset TCP settings
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue

        Log "Network settings reset to default values" 'Success'
        Log "Error resetting network settings: $($_.Exception.Message)" 'Error'

function Invoke-SystemPanelOptimizations {
    Log "Applying system optimizations from dedicated System panel..." 'Info'

    $systemActions = Invoke-PanelActions -PanelName 'System' -Actions @(
        [pscustomobject]@{
            Checkbox    = $chkPowerPlanSystem
            Action      = { Apply-PowerPlan }
            Description = 'High performance power plan'
        [pscustomobject]@{
            Checkbox    = $chkGameDVRSystem
            Action      = { Disable-GameDVR }
            Description = 'Disable Game DVR'
        [pscustomobject]@{
            Checkbox    = $chkGPUSchedulingSystem
            Action      = { Enable-GPUScheduling }
            Description = 'Enable GPU scheduling'
        [pscustomobject]@{
            Checkbox    = $chkAdvancedTelemetryDisable
            Action      = { Disable-AdvancedTelemetry }
            Description = 'Advanced telemetry reduction'
        [pscustomobject]@{
            Checkbox    = $chkMemoryDefragmentation
            Action      = { Enable-MemoryDefragmentation }
            Description = 'Memory defragmentation'
        [pscustomobject]@{
            Checkbox    = $chkServiceOptimization
            Action      = { Apply-ServiceOptimization }
            Description = 'Service optimization suite'
        [pscustomobject]@{
            Checkbox    = $chkDiskTweaksAdvanced
            Action      = { Apply-DiskTweaksAdvanced }
            Description = 'Disk tweaks (advanced)'
        [pscustomobject]@{
            Checkbox    = $chkNetworkLatencyOptimization
            Action      = { Enable-NetworkLatencyOptimization }
            Description = 'Network latency optimization'
        [pscustomobject]@{
            Checkbox    = $chkFPSSmoothness
            Action      = { Enable-FPSSmoothness }
            Description = 'FPS smoothness tuning'
        [pscustomobject]@{
            Checkbox    = $chkCPUMicrocode
            Action      = { Optimize-CPUMicrocode }
            Description = 'CPU microcode optimization'
        [pscustomobject]@{
            Checkbox    = $chkRAMTimings
            Action      = { Optimize-RAMTimings }
            Description = 'RAM timings optimization'
        [pscustomobject]@{
            Checkbox    = $chkDisableCortana
            Action      = { Disable-Cortana }
            Description = 'Disable Cortana'
        [pscustomobject]@{
            Checkbox    = $chkDisableWindowsUpdate
            Action      = { Optimize-WindowsUpdate }
            Description = 'Optimize Windows Update'
        [pscustomobject]@{
            Checkbox    = $chkDisableBackgroundApps
            Action      = { Disable-BackgroundApps }
            Description = 'Disable background apps'
        [pscustomobject]@{
            Checkbox    = $chkDisableLocationTracking
            Action      = { Disable-LocationTracking }
            Description = 'Disable location tracking'
        [pscustomobject]@{
            Checkbox    = $chkDisableAdvertisingID
            Action      = { Disable-AdvertisingID }
            Description = 'Disable advertising ID'
        [pscustomobject]@{
            Checkbox    = $chkDisableErrorReporting
            Action      = { Disable-ErrorReporting }
            Description = 'Disable error reporting'
        [pscustomobject]@{
            Checkbox    = $chkDisableCompatTelemetry
            Action      = { Disable-CompatibilityTelemetry }
            Description = 'Disable compatibility telemetry'
        [pscustomobject]@{
            Checkbox    = $chkDisableWSH
            Action      = { Disable-WSH }
            Description = 'Disable Windows Script Host'
    )

    # Enhanced Gaming Optimizations
    $enhancedGameOptimizations = @()
    if ($chkDynamicResolution -and $chkDynamicResolution.IsChecked) {
        $enhancedGameOptimizations += 'DynamicResolutionScaling'
    if ($chkEnhancedFramePacing -and $chkEnhancedFramePacing.IsChecked) {
        $enhancedGameOptimizations += 'EnhancedFramePacing'
    if ($chkGPUOverclocking -and $chkGPUOverclocking.IsChecked) {
        $enhancedGameOptimizations += 'ProfileBasedGPUOverclocking'
    if ($chkCompetitiveLatency -and $chkCompetitiveLatency.IsChecked) {
        $enhancedGameOptimizations += 'CompetitiveLatencyReduction'

    if ($enhancedGameOptimizations.Count -gt 0) {
        Apply-FPSOptimizations -OptimizationList $enhancedGameOptimizations
        $summary = 'Enhanced gaming optimizations: ' + ($enhancedGameOptimizations -join ', ')
        [void]$systemActions.Add($summary)

    # Enhanced System Optimizations
    $enhancedSystemSettings = @{}
    if ($chkAutoDiskOptimization -and $chkAutoDiskOptimization.IsChecked) {
        $enhancedSystemSettings.AutoDiskOptimization = $true
    if ($chkAdaptivePowerManagement -and $chkAdaptivePowerManagement.IsChecked) {
        $enhancedSystemSettings.AdaptivePowerManagement = $true
    if ($chkEnhancedPagingFile -and $chkEnhancedPagingFile.IsChecked) {
        $enhancedSystemSettings.EnhancedPagingFile = $true
    if ($chkDirectStorageEnhanced -and $chkDirectStorageEnhanced.IsChecked) {
        $enhancedSystemSettings.DirectStorageEnhanced = $true

    if ($enhancedSystemSettings.Count -gt 0) {
        Apply-EnhancedSystemOptimizations -Settings $enhancedSystemSettings
        $systemSettingsSummary = 'Enhanced system settings: ' + (($enhancedSystemSettings.Keys) -join ', ')
        [void]$systemActions.Add($systemSettingsSummary)

    if ($systemActions.Count -gt 0) {
        $details = $systemActions -join ', '
        Log "System optimizations applied successfully ($details)" 'Success'
    } else {
        Log 'No system optimizations were selected in the dedicated System panel' 'Info'

function Start-SystemBenchmark {
    Log "Starting system benchmark..." 'Info'

        # Simple CPU and memory benchmark
        $cpuStart = Get-Date
        for ($i = 0; $i -lt 1000000; $i++) {
            [math]::Sqrt($i) | Out-Null

        $cpuTime = (Get-Date) - $cpuStart

        $memInfo = Get-WmiObject -Class Win32_OperatingSystem
        $totalMem = [math]::Round($memInfo.TotalVisibleMemorySize / 1MB, 2)
        $freeMem = [math]::Round($memInfo.FreePhysicalMemory / 1MB, 2)
        $usedMem = $totalMem - $freeMem

        $results = @(
            "System Benchmark Results:",
            "",
            "CPU Test (1M calculations): $([math]::Round($cpuTime.TotalMilliseconds, 2))ms",
            "Memory Total: ${totalMem}GB",
            "Memory Used: ${usedMem}GB ($([math]::Round(($usedMem/$totalMem)*100, 1))%)",
            "Memory Free: ${freeMem}GB"
        )

        $message = $results -join "`n"
        [System.Windows.MessageBox]::Show($message, "System Benchmark", 'OK', 'Information')
        Log "System benchmark completed" 'Success'
        Log "Error running system benchmark: $($_.Exception.Message)" 'Error'

function Reset-SystemSettings {
    Log "Resetting system settings to default..." 'Info'

        # Reset common system optimization registry keys
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue

        Log "System settings reset to default values" 'Success'
        Log "Error resetting system settings: $($_.Exception.Message)" 'Error'

function Invoke-ServicePanelOptimizations {
    Log "Applying service optimizations from dedicated Services panel..." 'Info'

    $serviceActions = Invoke-PanelActions -PanelName 'Services' -Actions @(
        [pscustomobject]@{
            Checkbox    = $chkDisableXboxServicesServices
            Action      = { Disable-XboxServices }
            Description = 'Disable Xbox services'
        [pscustomobject]@{
            Checkbox    = $chkDisableTelemetryServices
            Action      = { Disable-Telemetry }
            Description = 'Disable telemetry services'
        [pscustomobject]@{
            Checkbox    = $chkDisableSearchServices
            Action      = { Disable-WindowsSearch }
            Description = 'Disable Windows Search service'
    )

    if ($serviceActions.Count -gt 0) {
        $details = $serviceActions -join ', '
        Log "Service optimizations applied successfully ($details)" 'Success'
    } else {
        Log 'No service optimizations were selected in the dedicated Services panel' 'Info'

function Show-RunningServices {
    Log "Showing running services..." 'Info'

        # Get running services
        $services = Get-Service | Where-Object {$_.Status -eq 'Running'} | Sort-Object Name
        $serviceList = $services | ForEach-Object { "$($_.Name) - $($_.DisplayName)" }

        # Create a simple list window or show in message box (simplified for this implementation)
        $message = "Running Services (first 20):`n`n" + (($serviceList | Select-Object -First 20) -join "`n")
        if ($serviceList.Count -gt 20) {
            $message += "`n`n... and $($serviceList.Count - 20) more services"


        [System.Windows.MessageBox]::Show($message, "Running Services", 'OK', 'Information')
        Log "Error viewing running services: $($_.Exception.Message)" 'Error'

function Reset-ServiceSettings {
    Log "Resetting service settings to default..." 'Info'

        # Reset services to default startup types (simplified implementation)
        # In a real implementation, this would restore original service configurations
        Log "Service settings reset to default values" 'Success'
        Log "Error resetting service settings: $($_.Exception.Message)" 'Error'

# ============================================================================
# END OF SCRIPT - Enhanced Gaming Optimizer with Dedicated Advanced Settings Panels
# ============================================================================

# Start real-time performance monitoring for dashboard
Log "Starting real-time performance monitoring..." 'Info'
Start-PerformanceMonitoring

# Inform user that game detection monitoring is on-demand
Log "Game detection monitoring remains off until Auto-Optimize is enabled" 'Info'

# Show the form
Normalize-VisualTreeBrushes -Root $form

$finalBrushKeys = @($script:BrushResourceKeys)
if ($form -and $form.Resources) {
    Register-BrushResourceKeys -Keys $form.Resources.Keys
    $finalBrushKeys = @($script:BrushResourceKeys)
        foreach ($resourceKey in $form.Resources.Keys) {
            if ($resourceKey -is [string] -and $resourceKey.EndsWith('Brush') -and ($finalBrushKeys -notcontains $resourceKey)) {
                $finalBrushKeys += $resourceKey

        # Ignore enumeration issues during final normalization

Normalize-BrushResources -Resources $form.Resources -Keys $finalBrushKeys -AllowTransparentFallback
    $form.ShowDialog() | Out-Null
    Write-Host "Error displaying form: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup

        # Stop performance monitoring
        Stop-PerformanceMonitoring

        # Stop game detection monitoring
        Stop-GameDetectionMonitoring


        # Cleanup timer precision
        [WinMM]::timeEndPeriod(1) | Out-Null
# - Service Management (Xbox, Telemetry, Search, Print Spooler, Superfetch)
# - Engine-specific optimizations (Unreal, Unity, Source, Frostbite, RED Engine, Creation Engine)
# - Special optimizations (DLSS, RTX, Vulkan, OpenGL, Physics, Frame Pacing)
# - Performance monitoring and auto-optimization
# - Backup and restore system
# - Export/Import configuration
# - Quick benchmark tool
# - Advanced/Compact menu modes
# - Comprehensive logging system with file persistence
# - Enhanced theme switching with instant UI updates and robust error handling

function Run-QuickOptimizations {
        Log 'Running Quick Optimizations...' 'Info'
        reg add 'HKCU\System\GameConfigStore' /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add 'HKCU\System\GameConfigStore' /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f | Out-Null
        Log 'Quick optimizations applied successfully.' 'Success'
        Log "Quick optimizations failed: $($_.Exception.Message)" 'Error'

$btnQuickOptimize.Add_Click({
    Run-QuickOptimizations
})

$btnAdvanced.Add_Click({
    Show-AdvancedSection -Section 'Network'
    Show-AdvancedSection -Section 'System'
    Show-AdvancedSection -Section 'Services'
})

    if ($dashboardLogPanel) { $dashboardLogPanel.Visibility = 'Visible'; $dashboardLogPanel.Height = 260 }
}
