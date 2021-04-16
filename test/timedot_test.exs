defmodule TimedotTest do
  use ExUnit.Case
  doctest Timedot

  @mixed_sample """
  # temporary comment
  2021-04-13
  test:dots  .... ... .. .
  test:integral  1
  test:decimal  13.37
  test:unit  1m
  """

  test "parse single day's entry" do
    single_day = "test:single  .5"

    assert {:ok, %Timedot.Item{quantity: {1_800, :seconds}}} =
             Timedot.parse_line(single_day, {2021, 4, 13})
  end

  test "parsing a comment line returns nil" do
    single_comment = "# test:single  .5"
    assert {:ok, nil} == Timedot.parse_line(single_comment, {2021, 4, 13})
  end

  test "parse mixed sample" do
    assert {:ok,
            %{
              items: [
                %Timedot.Item{
                  date: {2021, 4, 13},
                  account: "test:dots",
                  quantity: {9_000, :seconds}
                },
                _,
                _,
                _
              ],
              ir: _
            }} = Timedot.parse(@mixed_sample)
  end

  test "current year autofill" do
    sample = """
    04-13
    test:one  1
    04/14
    test:two  2h
    """

    assert {:ok,
            %{
              items: [
                %Timedot.Item{
                  date: {2021, 4, 13},
                  account: "test:one",
                  quantity: {3_600, :seconds}
                },
                %Timedot.Item{date: {2021, 4, 14}, quantity: {7_200, :seconds}}
              ],
              ir: _
            }} = Timedot.parse(sample)
  end

  test "to_string" do
    sample = """
    2021-04-13
    test:foo  1
    test:bar  2
    """

    expected_string = """
    2021-04-13
    test:foo  3600s
    test:bar  7200s
    """

    {:ok, parsed} = Timedot.parse(sample)
    assert Timedot.to_string(parsed) == expected_string
  end

  test "IR.to_string" do
    sample = """
    2021-04-13 ;Comment
    test:foo  .... .
     # Line comment
    test:bar  2s # Comment
    """

    expected = """
    2021-04-13 # Comment
    test:foo  .... .
    # Line comment
    test:bar  2s # Comment
    """

    {:ok, parsed} = Timedot.parse(sample)
    assert expected == Timedot.IR.to_string(parsed.ir)
  end

  test "invalid timedot leads to {:error, msg}" do
    bad_sample = """
    2021-04-13
    single:space .
    """

    assert {:error, _} = Timedot.parse(bad_sample)
  end
end
