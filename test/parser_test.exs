defmodule ParserTest do
  use ExUnit.Case
  doctest Timedot.Parser

  # Read timedot files
  defp read_file(filename), do: File.read!("test/support/#{filename}")

  test "parse the sample" do
    assert {:ok, [{:comment, _}, {:day, _}, {:day, _}, {:day, _}, {:day, _}], _, _, _, _} =
             Timedot.Parser.parse(read_file("sample.timedot"))
  end

  test "parse day without entries" do
    sample = """
    2021/04/13
    """

    assert {:ok, [{:day, %{entries: []}}], _, _, _, _} = Timedot.Parser.parse(sample)
  end

  test "parse the multi-day, dotted short sample" do
    assert {:ok,
            [{:comment, _}, {:day, _}, {:day, %{year: 2016, month: 2, day: 2, entries: [_, _]}}],
            _, _, _, _} = Timedot.Parser.parse(read_file("short_sample_1.timedot"))
  end

  test "parse the single-day, hours short sample" do
    assert {:ok,
            [
              {:day,
               %{
                 year: 2016,
                 month: 2,
                 day: 3,
                 entries: [_, {:entry, %{account: "fos:hledger", quantity: {:hours, 3}}}, _]
               }}
            ], _, _, _, _} = Timedot.Parser.parse(read_file("short_sample_2.timedot"))
  end

  test "fail to parse the org-mode sample" do
    assert {:error, _msg, _, _, _, _} = Timedot.Parser.parse(read_file("short_sample_3.timedot"))
  end

  test "fail to parse the long org-mode sample with timelog" do
    assert {:error, _msg, _, _, _, _} = Timedot.Parser.parse(read_file("short_sample_4.timedot"))
  end

  test "parse line with dots" do
    entry = "test:account  ..."

    assert {:ok, [{:entry, %{account: "test:account", quantity: {:dots, 3}}}], "", _, _, _} =
             Timedot.Parser.parse_line(entry)
  end

  test "parse line entry with unit" do
    entry = "test:account  60s"

    assert {:ok, [{:entry, %{account: "test:account", quantity: {:seconds, 60}}}], "", _, _, _} =
             Timedot.Parser.parse_line(entry)
  end

  test "parse line entry with integral hours and comment" do
    entry = "test:account  3 ; test"

    assert {:ok, [{:entry, %{account: "test:account", quantity: {:hours, 3}, comment: "test"}}],
            "", _, _, _} = Timedot.Parser.parse_line(entry)
  end

  test "parse line entry with decimal hours and comment" do
    entry = "test:account  3.5 ; test"

    assert {:ok, [{:entry, %{account: "test:account", quantity: {:hours, 3.5}, comment: "test"}}],
            "", _, _, _} = Timedot.Parser.parse_line(entry)
  end

  test "parse line entry account name with spaces" do
    entry = "test account  ..."

    assert {:ok, [{:entry, %{account: "test account", quantity: {:dots, 3}}}], "", _, _, _} =
             Timedot.Parser.parse_line(entry)
  end

  test "parsing fails on line without two spaces between" do
    entry = "test:account ..."

    assert {:error, "expected 2 or more spaces" <> _, "", _, _, _} =
             Timedot.Parser.parse_line(entry)
  end

  test "parse day with comment" do
    sample = """
    2021/04/13 ; Comment
    # Comment line
    test  1
    """

    assert {:ok,
            [
              {:day,
               %{
                 year: 2021,
                 month: 4,
                 day: 13,
                 comment: "Comment",
                 entries: [
                   {:comment, "Comment line"},
                   {:entry, %{account: "test", quantity: {:hours, 1}}}
                 ]
               }}
            ], _, _, _, _} = Timedot.Parser.parse(sample)
  end
end
