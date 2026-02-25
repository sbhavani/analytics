defmodule Plausible.Stats.CompareTest do
  use Plausible.DataCase, async: true
  alias Plausible.Stats.Compare

  describe "percent_change/2" do
    test "returns nil when old_count is nil" do
      assert Compare.percent_change(nil, 100) == nil
    end

    test "returns nil when new_count is nil" do
      assert Compare.percent_change(100, nil) == nil
    end

    test "returns nil when both are nil" do
      assert Compare.percent_change(nil, nil) == nil
    end

    test "returns 100 when old_count is 0 and new_count is positive" do
      assert Compare.percent_change(0, 100) == 100
    end

    test "returns 0 when old_count is 0 and new_count is also 0" do
      assert Compare.percent_change(0, 0) == 0
    end

    test "returns positive percentage when value increased" do
      assert Compare.percent_change(100, 150) == 50
    end

    test "returns negative percentage when value decreased" do
      assert Compare.percent_change(100, 50) == -50
    end

    test "returns 0 when values are equal" do
      assert Compare.percent_change(100, 100) == 0
    end

    test "handles large numbers" do
      assert Compare.percent_change(1_000_000, 1_500_000) == 50
    end

    test "handles decimal values" do
      assert Compare.percent_change(10.0, 15.0) == 50
    end
  end

  describe "percent_change/2 with map input" do
    test "extracts value from map with :value key" do
      assert Compare.percent_change(%{value: 100}, %{value: 150}) == 50
    end

    test "returns nil when old_count map has nil value" do
      assert Compare.percent_change(%{value: nil}, %{value: 100}) == nil
    end

    test "returns nil when new_count map has nil value" do
      assert Compare.percent_change(%{value: 100}, %{value: nil}) == nil
    end
  end

  describe "calculate_change/3" do
    test "returns percentage change for default metric" do
      assert Compare.calculate_change(:visitors, 100, 150) == 50
      assert Compare.calculate_change(:visitors, 100, 50) == -50
    end

    test "returns absolute difference for conversion_rate" do
      assert Compare.calculate_change(:conversion_rate, 5.0, 10.0) == 5.0
    end

    test "returns absolute difference for exit_rate" do
      assert Compare.calculate_change(:exit_rate, 20.0, 25.0) == 5.0
    end

    test "exit_rate returns nil when values are not floats" do
      assert Compare.calculate_change(:exit_rate, nil, 25.0) == nil
    end

    test "returns difference for bounce_rate" do
      assert Compare.calculate_change(:bounce_rate, 50, 40) == -10
    end

    test "bounce_rate returns nil when old_count is 0" do
      assert Compare.calculate_change(:bounce_rate, 0, 50) == nil
    end

    test "handles pageviews metric" do
      assert Compare.calculate_change(:pageviews, 1000, 1200) == 20
    end

    test "handles events metric" do
      assert Compare.calculate_change(:events, 500, 300) == -40
    end
  end
end
