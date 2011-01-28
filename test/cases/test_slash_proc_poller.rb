require 'helper'

class TestSlashProcPoller < Test::Unit::TestCase

  SIMPLE_PROC_LINE = "1 (init) S 0 0 0 0 -1 8388864 3706 282132 19 212 3 154 284 279 16 0 1 6714 115 1626112 130 4294967295 134512640 134540142 2948335296 2948334000 2817780216 0 0 1475401980 671819267 0 0 0 0 0 0 0"

  PROC_LINE_WITH_SPACE = "1 (my app) S 0 0 0 0 -1 8388864 3706 282132 19 212 3 154 284 279 16 0 1 6714 115 1626112 130 4294967295 134512640 134540142 2948335296 2948334000 2817780216 0 0 1475401980 671819267 0 0 0 0 0 0 0"


  test "memory should return 10" do
    File.stubs(:open).with(God::System::SlashProcPoller::MeminfoPath).returns(50)
    File.expects(:read).with("/proc/1/stat").returns(SIMPLE_PROC_LINE)

    slash_proc_poller = God::System::SlashProcPoller.new(1)

    assert_equal 520, slash_proc_poller.memory
  end

  test "memory should return 10 when whitespace is in the command field of the stat file" do
    File.stubs(:open).with(God::System::SlashProcPoller::MeminfoPath).returns(50)
    File.expects(:read).with("/proc/1/stat").returns(PROC_LINE_WITH_SPACE)

    slash_proc_poller = God::System::SlashProcPoller.new(1)

    assert_equal 520, slash_proc_poller.memory
  end

end
